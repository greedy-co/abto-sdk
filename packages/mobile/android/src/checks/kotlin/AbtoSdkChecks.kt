import app.abto.sdk.AbtoClient
import app.abto.sdk.AbtoConfig
import app.abto.sdk.AbtoContext
import app.abto.sdk.AbtoEnvironment
import app.abto.sdk.AbtoInMemoryStore
import app.abto.sdk.AbtoInitException
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.system.exitProcess

// 프레임워크 없는 검증 러너 — 실패 시 exit 1.
// ABTO_E2E=1 이고 dev collector(:4870)가 떠 있으면 실제 전송까지 검증한다.

var failures = 0

fun check(condition: Boolean, name: String) {
    if (condition) {
        println("ok   $name")
    } else {
        failures += 1
        println("FAIL $name")
    }
}

fun isUuidV7(value: String): Boolean =
    Regex("^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$").matches(value)

fun main() {
    // init config validation
    val config = AbtoConfig(projectKey = "ek_test")
    check(config.endpoint == "https://api.abto.app/v1/collect/events", "default endpoint derived")
    check(config.environment == AbtoEnvironment.PRODUCTION && !config.debug, "production defaults")
    check(AbtoConfig("ek", environment = AbtoEnvironment.DEVELOPMENT).debug, "development turns debug on")

    try {
        AbtoConfig(projectKey = "  ")
        check(false, "empty projectKey rejected")
    } catch (e: AbtoInitException) {
        check(e.message == "[abto] projectKey is required. Check your init config.", "empty projectKey rejected")
    }

    try {
        AbtoConfig(projectKey = "ek", endpoint = "htp:/broken url")
        check(false, "malformed endpoint rejected")
    } catch (e: AbtoInitException) {
        check(e.message!!.startsWith("[abto] endpoint is not a valid http(s) URL:"), "malformed endpoint rejected")
    }

    try {
        AbtoConfig(projectKey = "ek", endpoint = "https:/collector")
        check(false, "endpoint without authority rejected")
    } catch (e: AbtoInitException) {
        check(e.message!!.startsWith("[abto] endpoint is not a valid http(s) URL:"), "endpoint without authority rejected")
    }

    try {
        AbtoConfig(projectKey = "ek", endpoint = "http://collector.example/v1/collect/events")
        check(false, "production cleartext endpoint rejected")
    } catch (e: AbtoInitException) {
        check(e.message == "[abto] endpoint must use HTTPS outside development loopback.", "production cleartext endpoint rejected")
    }
    check(
        AbtoConfig(
            projectKey = "ek",
            endpoint = "http://127.0.0.1:4870/v1/collect/events",
            environment = AbtoEnvironment.DEVELOPMENT,
        ).endpoint.startsWith("http://127.0.0.1"),
        "development loopback endpoint accepted",
    )

    for (invalidBatchSize in listOf(0, 101)) {
        try {
            AbtoConfig(projectKey = "ek", batchSize = invalidBatchSize)
            check(false, "batchSize $invalidBatchSize rejected")
        } catch (e: AbtoInitException) {
            check(e.message == "[abto] batchSize must be between 1 and 100.", "batchSize $invalidBatchSize rejected")
        }
    }

    // context identity
    val store = AbtoInMemoryStore()
    val first = AbtoContext(store)
    val second = AbtoContext(store)
    check(first.anonymousId == second.anonymousId, "anonymous_id persists across clients")
    check(isUuidV7(first.anonymousId), "anonymous_id uses UUIDv7")
    check(isUuidV7(first.sessionId), "session_id uses UUIDv7")
    check(first.sessionId != second.sessionId, "session_id rotates per client")

    first.identify("u_1", "t_1")
    check(first.commonProperties()["user_id"] == "u_1", "identify sets user_id")
    first.identify("u_2")
    check(!first.commonProperties().containsKey("tenant_id"), "identify clears an omitted tenant_id")
    val anonBefore = first.anonymousId
    first.reset()
    check(!first.commonProperties().containsKey("user_id"), "reset clears user_id")
    check(first.anonymousId != anonBefore, "reset rotates anonymous_id")

    val identityClient = AbtoClient(AbtoConfig("ek_identity"), AbtoInMemoryStore())
    val clientDeviceBeforeReset = identityClient.deviceId
    check(isUuidV7(clientDeviceBeforeReset), "client exposes Gateway attribution deviceId")
    check(isUuidV7(identityClient.sessionId), "client exposes sessionId")
    identityClient.reset()
    check(identityClient.deviceId != clientDeviceBeforeReset, "client deviceId follows reset")
    check(!identityClient.capture("pageview"), "reserved system event name rejected by public capture")
    check(!identityClient.capture("x".repeat(201)), "overlong event name rejected before enqueue")
    check(!identityClient.capture("🙂".repeat(101)), "event name limit uses backend UTF-16 units")

    // trace request id join
    val client = AbtoClient(AbtoConfig("ek_test"), AbtoInMemoryStore())
    val trace = client.startLlmTrace(nodeId = "smoke.demo")
    check(Regex("^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$").matches(trace.traceId), "trace_id uses UUIDv7 bits")
    check(trace.attachRequestId(mapOf("X-Request-Id" to listOf("req_1"))) == "req_1", "attachRequestId reads header case-insensitively")
    check(trace.requestId == "req_1", "requestId retained on trace")

    // collector per-event retry
    val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    val requests = CopyOnWriteArrayList<List<String>>()
    val requestBodies = CopyOnWriteArrayList<String>()
    val requestCount = AtomicInteger()
    val oversizedRequestCount = AtomicInteger()
    val unavailableRequestCount = AtomicInteger()
    val blockedRequestCount = AtomicInteger()
    val blockedEventCount = AtomicInteger()
    val secondRetryRequest = CountDownLatch(1)
    val oversizedRetryRequest = CountDownLatch(1)
    val unavailableRetryBudgetReached = CountDownLatch(3)
    val blockedRequestStarted = CountDownLatch(1)
    val releaseBlockedRequest = CountDownLatch(1)
    val boundedBurstRequests = CountDownLatch(11)
    server.executor = Executors.newCachedThreadPool { runnable ->
        Thread(runnable, "abto-sdk-check-server").apply { isDaemon = true }
    }
    server.createContext("/always-unavailable") { exchange ->
        exchange.requestBody.use { it.readBytes() }
        unavailableRequestCount.incrementAndGet()
        unavailableRetryBudgetReached.countDown()
        exchange.sendResponseHeaders(503, -1)
        exchange.close()
    }
    server.createContext("/blocked-success") { exchange ->
        val requestBody = exchange.requestBody.bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
        val eventIds = Regex(""""event_id":"([^"]+)"""").findAll(requestBody).map { it.groupValues[1] }.toList()
        val attempt = blockedRequestCount.incrementAndGet()
        blockedEventCount.addAndGet(eventIds.size)
        if (attempt == 1) {
            blockedRequestStarted.countDown()
            releaseBlockedRequest.await(10, TimeUnit.SECONDS)
        }
        val results = eventIds.joinToString(",") { eventId ->
            """"$eventId":{"result":"ok"}"""
        }
        val response = """{"results":{$results}}""".toByteArray(StandardCharsets.UTF_8)
        exchange.responseHeaders.set("content-type", "application/json")
        exchange.sendResponseHeaders(202, response.size.toLong())
        exchange.responseBody.use { it.write(response) }
        boundedBurstRequests.countDown()
    }
    server.createContext("/v1/collect/events") { exchange ->
        val requestBody = exchange.requestBody.bufferedReader(StandardCharsets.UTF_8).use { it.readText() }
        requestBodies.add(requestBody)
        val eventIds = Regex(""""event_id":"([^"]+)"""").findAll(requestBody).map { it.groupValues[1] }.toList()
        if (requestBody.contains(""""event_name":"oversized_response"""")) {
            val attempt = oversizedRequestCount.incrementAndGet()
            if (attempt == 2) oversizedRetryRequest.countDown()
            val response = if (attempt == 1) {
                ByteArray(64 * 1024 + 1)
            } else {
                val results = eventIds.joinToString(",") { eventId ->
                    """"$eventId":{"result":"ok"}"""
                }
                """{"results":{$results}}""".toByteArray(StandardCharsets.UTF_8)
            }
            exchange.sendResponseHeaders(202, response.size.toLong())
            exchange.responseBody.use { it.write(response) }
            return@createContext
        }
        requests.add(eventIds)
        val attempt = requestCount.incrementAndGet()
        if (attempt == 2) secondRetryRequest.countDown()
        val results = eventIds.joinToString(",") { eventId ->
            val result = if (attempt == 1 && eventId == eventIds.first()) "retry" else "ok"
            """"$eventId":{"result":"$result"}"""
        }
        val response = """{"results":{$results}}""".toByteArray(StandardCharsets.UTF_8)
        exchange.responseHeaders.set("content-type", "application/json")
        exchange.sendResponseHeaders(202, response.size.toLong())
        exchange.responseBody.use { it.write(response) }
    }
    server.start()
    try {
        val unavailableClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_unavailable",
                endpoint = "http://127.0.0.1:${server.address.port}/always-unavailable",
                environment = AbtoEnvironment.DEVELOPMENT,
                debug = false,
                batchSize = 1,
                flushIntervalMs = 10,
            ),
            AbtoInMemoryStore(),
        )
        unavailableClient.capture("bounded_retry")
        check(
            unavailableRetryBudgetReached.await(5, TimeUnit.SECONDS),
            "unavailable collector reaches the retry attempt budget",
        )
        Thread.sleep(300)
        check(unavailableRequestCount.get() == 3, "unavailable collector stops after three attempts")

        val burstClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_burst",
                endpoint = "http://127.0.0.1:${server.address.port}/blocked-success",
                environment = AbtoEnvironment.DEVELOPMENT,
                debug = false,
                batchSize = 100,
                flushIntervalMs = 10_000,
            ),
            AbtoInMemoryStore(),
        )
        repeat(100) { burstClient.capture("burst_initial_$it") }
        check(blockedRequestStarted.await(5, TimeUnit.SECONDS), "burst transport starts one in-flight request")
        repeat(2_000) { burstClient.capture("burst_buffered_$it") }
        releaseBlockedRequest.countDown()
        check(boundedBurstRequests.await(10, TimeUnit.SECONDS), "bounded burst drains the retained buffer")
        Thread.sleep(300)
        check(blockedRequestCount.get() == 11, "burst coalesces flush work and caps queued batches")
        check(blockedEventCount.get() == 1_100, "burst retains at most one thousand buffered events")

        val oversizedClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_oversized",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
                flushIntervalMs = 50,
            ),
            AbtoInMemoryStore(),
        )
        oversizedClient.capture("oversized_response")
        val oversizedFlush = CountDownLatch(1)
        oversizedClient.flush { oversizedFlush.countDown() }
        check(oversizedFlush.await(10, TimeUnit.SECONDS), "oversized response flush completed")
        check(oversizedRetryRequest.await(10, TimeUnit.SECONDS), "oversized collector response is retried")

        val retryClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_retry",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
                flushIntervalMs = 50,
            ),
            AbtoInMemoryStore(),
        )
        retryClient.capture("first")
        retryClient.capture("second")
        val firstFlush = CountDownLatch(1)
        retryClient.flush { firstFlush.countDown() }
        check(firstFlush.await(10, TimeUnit.SECONDS), "first retry flush completed")
        check(secondRetryRequest.await(10, TimeUnit.SECONDS), "retry schedules a second request")
        check(requests.size == 2, "retry causes a second request")
        check(requests.getOrNull(0)?.size == 2, "first request contains the full batch")
        check(
            requests.getOrNull(1) == listOf(requests.first().first()),
            "second request contains only the retry event",
        )

        val finiteClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_finite",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
            ),
            AbtoInMemoryStore(),
        )
        finiteClient.capture("invalid_metric", value = Double.NaN)
        val finiteFlush = CountDownLatch(1)
        finiteClient.flush { finiteFlush.countDown() }
        check(finiteFlush.await(10, TimeUnit.SECONDS), "non-finite metric flush completed")
        val finiteBody = requestBodies.lastOrNull { it.contains(""""event_name":"invalid_metric"""") }.orEmpty()
        check(!finiteBody.contains("NaN") && !finiteBody.contains("\"value\":"), "non-finite metric value omitted")

        finiteClient.identify("real-user", "real-tenant")
        finiteClient.capture(
            "bounded_metric",
            properties = mapOf(
                "environment" to "customer-environment",
                "user_id" to "customer-user",
                "\$environment" to "spoofed",
                "\$user_id" to "spoofed",
            ),
            value = 1.0 / 3.0,
            scale = "x".repeat(17),
        )
        val boundedFlush = CountDownLatch(1)
        finiteClient.flush { boundedFlush.countDown() }
        check(boundedFlush.await(10, TimeUnit.SECONDS), "precision-bounded metric flush completed")
        val boundedBody = requestBodies.lastOrNull { it.contains(""""event_name":"bounded_metric"""") }.orEmpty()
        check(!boundedBody.contains("\"value\":"), "over-precision metric value omitted")
        check(!boundedBody.contains("\"scale\":"), "oversized metric scale omitted")
        check(boundedBody.contains("\"environment\":\"customer-environment\""), "customer environment property retained")
        check(boundedBody.contains("\"user_id\":\"customer-user\""), "customer user_id property retained")
        check(boundedBody.contains("\"\$environment\":\"development\""), "SDK environment context is namespaced")
        check(boundedBody.contains("\"\$user_id\":\"real-user\""), "SDK user context cannot be overwritten")
        check(!boundedBody.contains("spoofed"), "customer reserved properties are rejected")

        val privacyClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_privacy",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
            ),
            AbtoInMemoryStore(),
        )
        val privacyTrace = privacyClient.startLlmTrace(nodeId = "assistant.reply", taskType = "answer")
        privacyTrace.submitPrompt(prompt = "prompt-canary")
        privacyTrace.attach("req_helper")
        privacyTrace.markResponseVisible(
            responseId = "response-1",
            responseText = "response-canary",
            timeToVisibleMs = 42,
        )
        privacyTrace.captureOutcome("copied", responseId = "response-1")
        val privacyFlush = CountDownLatch(1)
        privacyClient.flush { privacyFlush.countDown() }
        check(privacyFlush.await(10, TimeUnit.SECONDS), "metadata-only LLM events flushed")
        val privacyBody = requestBodies.lastOrNull().orEmpty()
        check(privacyBody.contains("\"event_name\":\"llm_prompt_submitted\""), "LLM prompt uses canonical event name")
        check(privacyBody.contains("\"event_name\":\"llm_response_rendered\""), "LLM response uses canonical rendered event name")
        check(privacyBody.contains("\"event_name\":\"llm_response_interacted\""), "LLM outcome uses canonical interaction event name")
        check(!privacyBody.contains("prompt-canary"), "prompt text is not transmitted")
        check(!privacyBody.contains("response-canary"), "response text is not transmitted")
        check(privacyBody.contains("\"\$capture_mode\":\"metadata_only\""), "metadata-only capture mode is transmitted")
        check(privacyBody.contains("\"\$prompt_length_chars\":13"), "prompt length metadata is transmitted")
        check(privacyBody.contains("\"\$output_length_chars\":15"), "response length metadata is transmitted")
        check(privacyBody.contains("\"\$interaction_type\":\"copied\""), "LLM helper emits canonical interaction type")
        check(privacyBody.contains("\"\$request_id\":\"req_helper\""), "LLM helper keeps request id in canonical context")
    } finally {
        server.stop(0)
    }

    // collector E2E (opt-in)
    if (System.getenv("ABTO_E2E") == "1") {
        val e2eClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_smoke_android",
                endpoint = "http://localhost:4870/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
            ),
            AbtoInMemoryStore(),
        )
        e2eClient.identify("u_smoke_android")
        val e2eTrace = e2eClient.startLlmTrace(nodeId = "smoke.android", taskType = "smoke_test", surface = "sdk_checks")
        e2eTrace.submitPrompt(prompt = "Android 스모크 프롬프트", language = "ko")
        e2eTrace.attach("req_smoke_android")
        e2eTrace.markResponseVisible(responseId = "resp_smoke_android", responseText = "Android 응답", timeToVisibleMs = 42)
        e2eTrace.captureOutcome("copied", responseId = "resp_smoke_android")

        val done = CountDownLatch(1)
        e2eClient.flush { done.countDown() }
        check(done.await(10, TimeUnit.SECONDS), "e2e flush to local collector completed")
    } else {
        println("skip e2e (set ABTO_E2E=1 with dev collector running)")
    }

    if (failures > 0) {
        println("$failures check(s) failed")
        exitProcess(1)
    }
    println("all checks passed")
}
