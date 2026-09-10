import app.abto.sdk.ABTO_CONFORMANCE_EXEMPTIONS
import app.abto.sdk.ABTO_CONFORMANCE_SCENARIOS
import app.abto.sdk.ABTO_ERR_BATCH_SIZE_RANGE
import app.abto.sdk.ABTO_ERR_ENDPOINT_HTTPS_REQUIRED
import app.abto.sdk.ABTO_ERR_ENDPOINT_INVALID_PREFIX
import app.abto.sdk.ABTO_ERR_PROJECT_KEY_REQUIRED
import app.abto.sdk.ABTO_MAX_ATTEMPTS
import app.abto.sdk.AbtoClient
import app.abto.sdk.AbtoConfig
import app.abto.sdk.AbtoContext
import app.abto.sdk.AbtoEnvironment
import app.abto.sdk.AbtoInMemoryStore
import app.abto.sdk.AbtoInitException
import app.abto.sdk.AbtoResponseInteraction
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.charset.StandardCharsets
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.system.exitProcess

// Framework-free verification runner that exits with status 1 on failure.
// Also verifies actual delivery when ABTO_E2E=1 and the development collector is running on port 4870.

var failures = 0

fun check(condition: Boolean, name: String) {
    if (condition) {
        println("ok   $name")
    } else {
        failures += 1
        println("FAIL $name")
    }
}

val covered = mutableSetOf<String>()

/** 이 검증이 증명하는 공통 시나리오를 기록한다. 목록의 정본은 계약이다. */
fun covers(scenario: String) {
    if (scenario !in ABTO_CONFORMANCE_SCENARIOS) {
        failures += 1
        println("FAIL unknown conformance scenario: $scenario")
        return
    }
    covered += scenario
}

fun checkConformanceCoverage() {
    ABTO_CONFORMANCE_EXEMPTIONS.forEach {
        println("exempt $it — declared in contracts/client-sdk/conformance.schema.json")
    }
    val missing = ABTO_CONFORMANCE_SCENARIOS
        .filterNot { it in covered || it in ABTO_CONFORMANCE_EXEMPTIONS }
    if (missing.isEmpty()) {
        println("ok   client conformance scenarios all covered")
    } else {
        failures += 1
        println("FAIL client conformance scenarios not covered: ${missing.joinToString(", ")}")
    }
}

fun isUuidV7(value: String): Boolean =
    Regex("^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$").matches(value)

fun main() {
    check(
        AbtoResponseInteraction.fromWireValue("copied") == AbtoResponseInteraction.COPIED,
        "canonical response interaction is accepted at runtime",
    )
    check(
        AbtoResponseInteraction.fromWireValue("retried") == null,
        "unknown response interaction is rejected at runtime",
    )

    // init config validation
    val config = AbtoConfig(projectKey = "ek_test")
    check(config.endpoint == "https://api.abto.app/v1/collect/events", "default endpoint derived")
    check(config.environment == AbtoEnvironment.PRODUCTION && !config.debug, "production defaults")
    check(AbtoConfig("ek", environment = AbtoEnvironment.DEVELOPMENT).debug, "development turns debug on")

    try {
        covers("config.project_key_required")
        AbtoConfig(projectKey = "  ")
        check(false, "empty projectKey rejected")
    } catch (e: AbtoInitException) {
        check(e.message == ABTO_ERR_PROJECT_KEY_REQUIRED, "empty projectKey rejected")
    }

    try {
        covers("config.endpoint_must_be_url")
        AbtoConfig(projectKey = "ek", endpoint = "htp:/broken url")
        check(false, "malformed endpoint rejected")
    } catch (e: AbtoInitException) {
        check(e.message!!.startsWith(ABTO_ERR_ENDPOINT_INVALID_PREFIX), "malformed endpoint rejected")
    }

    try {
        AbtoConfig(projectKey = "ek", endpoint = "https:/collector")
        check(false, "endpoint without authority rejected")
    } catch (e: AbtoInitException) {
        check(e.message!!.startsWith(ABTO_ERR_ENDPOINT_INVALID_PREFIX), "endpoint without authority rejected")
    }

    try {
        covers("config.endpoint_requires_https")
        AbtoConfig(projectKey = "ek", endpoint = "http://collector.example/v1/collect/events")
        check(false, "production cleartext endpoint rejected")
    } catch (e: AbtoInitException) {
        check(e.message == ABTO_ERR_ENDPOINT_HTTPS_REQUIRED, "production cleartext endpoint rejected")
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
            covers("config.batch_size_range")
            AbtoConfig(projectKey = "ek", batchSize = invalidBatchSize)
            check(false, "batchSize $invalidBatchSize rejected")
        } catch (e: AbtoInitException) {
            check(e.message == ABTO_ERR_BATCH_SIZE_RANGE, "batchSize $invalidBatchSize rejected")
        }
    }

    // context identity
    val store = AbtoInMemoryStore()
    val first = AbtoContext(store)
    val second = AbtoContext(store)
    covers("identity.anonymous_persists")
    check(first.anonymousId == second.anonymousId, "anonymous_id persists across clients")
    covers("identity.uuidv7")
    check(isUuidV7(first.anonymousId), "anonymous_id uses UUIDv7")
    check(isUuidV7(first.sessionId), "session_id uses UUIDv7")
    covers("identity.session_rotates")
    check(first.sessionId != second.sessionId, "session_id rotates per client")

    first.identify("u_1", "t_1")
    covers("identity.identify_and_reset")
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
    // trace request id join
    val client = AbtoClient(AbtoConfig("ek_test"), AbtoInMemoryStore())
    val trace = client.startLlmTrace(featureId = "smoke.demo")
    check(trace.featureId == "smoke.demo", "featureId retained on trace")
    check(Regex("^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$").matches(trace.traceId), "trace_id uses UUIDv7 bits")
    covers("transport.request_id_header_case_insensitive")
    check(trace.attachRequestId(mapOf("X-Abto-Request-Id" to listOf("req_1"))) == "req_1", "attachRequestId reads header case-insensitively")
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
    val unavailableRetryBudgetReached = CountDownLatch(ABTO_MAX_ATTEMPTS)
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
        unavailableClient.capture(event = "bounded_retry", value = 1, scale = "count")
        check(
            unavailableRetryBudgetReached.await(5, TimeUnit.SECONDS),
            "unavailable collector reaches the retry attempt budget",
        )
        Thread.sleep(300)
        covers("transport.attempt_budget_stops_retry")
        check(
            unavailableRequestCount.get() == ABTO_MAX_ATTEMPTS,
            "unavailable collector stops at the retry attempt budget",
        )

        val burstClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_burst",
                endpoint = "http://127.0.0.1:${server.address.port}/blocked-success",
                environment = AbtoEnvironment.DEVELOPMENT,
                debug = false,
                batchSize = 100,
                flushIntervalMs = 10000,
            ),
            AbtoInMemoryStore(),
        )
        repeat(100) { burstClient.capture(event = "burst_initial_$it", value = 1, scale = "count") }
        check(blockedRequestStarted.await(5, TimeUnit.SECONDS), "burst transport starts one in-flight request")
        repeat(2000) { burstClient.capture(event = "burst_buffered_$it", value = 1, scale = "count") }
        releaseBlockedRequest.countDown()
        check(boundedBurstRequests.await(10, TimeUnit.SECONDS), "bounded burst drains the retained buffer")
        Thread.sleep(300)
        check(blockedRequestCount.get() == 11, "burst coalesces flush work and caps queued batches")
        covers("transport.buffer_cap")
        check(blockedEventCount.get() == 1100, "burst retains at most one thousand buffered events")

        val oversizedClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_oversized",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
                flushIntervalMs = 50,
            ),
            AbtoInMemoryStore(),
        )
        oversizedClient.capture(event = "oversized_response", value = 1, scale = "count")
        val oversizedFlush = CountDownLatch(1)
        oversizedClient.flush { oversizedFlush.countDown() }
        check(oversizedFlush.await(10, TimeUnit.SECONDS), "oversized response flush completed")
        covers("transport.response_body_cap")
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
        retryClient.capture(event = "first", value = 1, scale = "count")
        retryClient.capture(event = "second", value = 1, scale = "count")
        val firstFlush = CountDownLatch(1)
        retryClient.flush { firstFlush.countDown() }
        check(firstFlush.await(10, TimeUnit.SECONDS), "first retry flush completed")
        check(secondRetryRequest.await(10, TimeUnit.SECONDS), "retry schedules a second request")
        covers("transport.retry_marked_events_only")
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
        // 잘못된 이름은 전송 자체가 일어나지 않아야 한다 — 반환값이 아니라 wire 로 확인한다.
        covers("event.reserved_name_rejected")
        covers("event.name_length_limit")
        finiteClient.capture(event = "pageview", value = 1, scale = "count")
        finiteClient.capture(event = "x".repeat(201), value = 1, scale = "count")
        finiteClient.capture(event = "🙂".repeat(101), value = 1, scale = "count")
        finiteClient.capture(event = "name_guard_probe", value = 1, scale = "count")
        val guardFlush = CountDownLatch(1)
        finiteClient.flush { guardFlush.countDown() }
        check(guardFlush.await(10, TimeUnit.SECONDS), "name guard flush completed")
        val guardBody = requestBodies.lastOrNull().orEmpty()
        check(guardBody.contains("name_guard_probe"), "a valid event name reaches the wire")
        check(!guardBody.contains("\"event_name\":\"pageview\""), "reserved system event name rejected by public capture")
        check(!guardBody.contains("x".repeat(201)), "overlong event name rejected before enqueue")
        check(!guardBody.contains("🙂".repeat(101)), "event name limit uses backend UTF-16 units")

        finiteClient.capture(event = "invalid_metric", value = Double.NaN, scale = "count")
        val finiteFlush = CountDownLatch(1)
        finiteClient.flush { finiteFlush.countDown() }
        check(finiteFlush.await(10, TimeUnit.SECONDS), "non-finite metric flush completed")
        val finiteBody = requestBodies.lastOrNull { it.contains(""""event_name":"invalid_metric"""") }.orEmpty()
        covers("event.metric_non_finite_rejected")
        check(finiteBody.isEmpty(), "non-finite metric event rejected")

        finiteClient.identify("real-user", "real-tenant")
        finiteClient.capture(event = "bounded_metric", value = 1.0 / 3.0, scale = "count")
        finiteClient.capture(event = "bad_scale", value = 1, scale = "x".repeat(17))
        finiteClient.capture(event = "bad_properties", value = 1, scale = "count", properties = mapOf("\$user_id" to "spoof"))
        val boundedFlush = CountDownLatch(1)
        finiteClient.flush { boundedFlush.countDown() }
        check(boundedFlush.await(10, TimeUnit.SECONDS), "precision-bounded metric flush completed")
        val boundedBody = requestBodies.lastOrNull { it.contains(""""event_name":"bounded_metric"""") }.orEmpty()
        covers("event.metric_precision_enforced")
        check(boundedBody.isEmpty(), "over-precision metric event rejected")
        covers("event.metric_scale_limit")
        check(requestBodies.none { it.contains("bad_scale") || it.contains("bad_properties") }, "invalid scale and properties rejected")

        covers("event.properties_in_extra_json")
        covers("event.promoted_fields_not_in_extra_json")
        finiteClient.capture(event = "promoted_metric", value = 49000, scale = "KRW", properties = mapOf("tier" to "pro", "nullable" to null, "tags" to listOf("a"), "detail" to mapOf("enabled" to true)))
        val promotedFlush = CountDownLatch(1)
        finiteClient.flush { promotedFlush.countDown() }
        check(promotedFlush.await(10, TimeUnit.SECONDS), "promoted metric flush completed")
        val promotedBody = requestBodies.lastOrNull { it.contains(""""event_name":"promoted_metric"""") }.orEmpty()
        // An Int literal reaches the wire as the same Double the other SDKs send.
        check(promotedBody.contains(""""value":49000.0"""), "metric value is promoted to the wire field")
        check(promotedBody.contains(""""scale":"KRW""""), "metric scale is promoted to the wire field")
        val promotedExtraJson = promotedBody.substringAfter("\"extra_json\":")
        check(promotedExtraJson.contains("\"tier\":\"pro\""), "user properties are in extra_json")
        check(promotedExtraJson.contains("\"nullable\":null"), "null custom properties retained")
        check(!promotedExtraJson.contains("\"properties\":"), "no properties wrapper on the wire")
        for (promoted in listOf("value", "scale", "\$device_id", "\$anonymous_id", "\$session_id", "\$trace_id")) {
            check(!promotedExtraJson.contains(""""$promoted""""), "$promoted is not copied into extra_json")
        }

        covers("event.optional_scale_preserved")
        for ((name, scale) in listOf("scale_omitted" to null, "scale_empty" to "")) {
            val before = requestBodies.size
            finiteClient.capture(event = name, value = 0, scale = scale)
            val done = CountDownLatch(1)
            finiteClient.flush { done.countDown() }
            check(done.await(10, TimeUnit.SECONDS), "optional scale flush completes")
            val body = requestBodies.drop(before).firstOrNull { it.contains(name) }.orEmpty()
            check(body.isNotEmpty(), "optional scale event reaches transport")
            if (scale == null) check(!body.contains("\"scale\":"), "omitted scale stays absent")
            else check(body.contains("\"scale\":\"\""), "empty scale is preserved")
        }

        covers("event.optional_metrics_preserved")
        for (name in listOf("name_only", "properties_only", "scale_only", "scale_only_empty")) {
            val before = requestBodies.size
            when (name) {
                "name_only" -> finiteClient.capture(name)
                "properties_only" -> finiteClient.capture(name, properties = mapOf("tier" to "pro"))
                "scale_only" -> finiteClient.capture(name, scale = "KRW")
                else -> finiteClient.capture(name, scale = "")
            }
            val done = CountDownLatch(1)
            finiteClient.flush { done.countDown() }
            check(done.await(10, TimeUnit.SECONDS), "optional metrics flush completes")
            val body = requestBodies.drop(before).firstOrNull { it.contains(name) }.orEmpty()
            check(body.isNotEmpty(), "optional metrics event reaches transport")
            check(!body.contains("\"value\":"), "omitted value stays absent")
            if (name == "scale_only") check(body.contains("\"scale\":\"KRW\""), "scale without value is preserved")
            else if (name == "scale_only_empty") check(body.contains("\"scale\":\"\""), "empty scale without value is preserved")
            else check(!body.contains("\"scale\":"), "omitted scale stays absent")
            if (name == "properties_only") check(body.contains("\"tier\":\"pro\""), "properties without metrics are preserved")
        }

        val privacyClient = AbtoClient(
            AbtoConfig(
                projectKey = "ek_privacy",
                endpoint = "http://127.0.0.1:${server.address.port}/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
            ),
            AbtoInMemoryStore(),
        )
        val privacyTrace = privacyClient.startLlmTrace(featureId = "assistant.reply", taskType = "answer")
        privacyTrace.submitPrompt(prompt = "prompt-canary")
        privacyTrace.attach("req_helper")
        privacyTrace.markResponseVisible(
            responseId = "response-1",
            responseText = "response-canary",
            timeToVisibleMs = 42,
        )
        privacyTrace.captureOutcome(AbtoResponseInteraction.COPIED, responseId = "response-1")
        val privacyFlush = CountDownLatch(1)
        privacyClient.flush { privacyFlush.countDown() }
        check(privacyFlush.await(10, TimeUnit.SECONDS), "metadata-only LLM events flushed")
        val privacyBody = requestBodies.lastOrNull().orEmpty()
        check(privacyBody.contains("\"event_name\":\"llm_prompt_submitted\""), "LLM prompt uses canonical event name")
        check(privacyBody.contains("\"event_name\":\"llm_response_rendered\""), "LLM response uses canonical rendered event name")
        check(privacyBody.contains("\"event_name\":\"llm_response_interacted\""), "LLM outcome uses canonical interaction event name")
        covers("privacy.prompt_and_response_text_not_sent")
        check(!privacyBody.contains("prompt-canary"), "prompt text is not transmitted")
        check(!privacyBody.contains("response-canary"), "response text is not transmitted")
        check(privacyBody.contains("\"\$capture_mode\":\"metadata_only\""), "metadata-only capture mode is transmitted")
        check(privacyBody.contains("\"\$prompt_length_chars\":13"), "prompt length metadata is transmitted")
        check(privacyBody.contains("\"\$output_length_chars\":15"), "response length metadata is transmitted")
        check(privacyBody.contains("\"\$interaction_type\":\"copied\""), "LLM helper emits canonical interaction type")
        check(privacyBody.contains("\"\$feature_id\":\"assistant.reply\""), "featureId maps to the collector contract")
        // The canonical type is now the only way in, so a non-canonical value cannot reach the wire.
        check(
            AbtoResponseInteraction.fromWireValue("retried") == null,
            "a non-canonical interaction type has no canonical value",
        )
        check(!privacyBody.contains("retried"), "LLM helper drops non-canonical interaction types")
        check(privacyBody.contains("\"\$request_id\":\"req_helper\""), "LLM helper keeps request id in canonical context")
    } finally {
        server.stop(0)
    }

    // collector E2E (opt-in)
    if (System.getenv("ABTO_E2E") == "1") {
        val e2eClient = AbtoClient(
            AbtoConfig(
                projectKey = System.getenv("ABTO_E2E_KEY") ?: "ek_smoke_android",
                endpoint = System.getenv("ABTO_E2E_ENDPOINT") ?: "http://localhost:4870/v1/collect/events",
                environment = AbtoEnvironment.DEVELOPMENT,
            ),
            AbtoInMemoryStore(),
        )
        e2eClient.capture("sdk_e2e_android_currency", value = 49000, scale = "KRW", properties = mapOf("tier" to "pro"))
        e2eClient.capture("sdk_e2e_android_omitted", value = 0)
        e2eClient.capture("sdk_e2e_android_empty", value = 0, scale = "")
        e2eClient.capture("sdk_e2e_android_name_only")
        e2eClient.capture("sdk_e2e_android_properties_only", properties = mapOf("tier" to "pro"))
        e2eClient.capture("sdk_e2e_android_scale_only", scale = "KRW")
        e2eClient.capture("sdk_e2e_android_scale_only_empty", scale = "")
        e2eClient.identify("u_smoke_android")
        val e2eTrace = e2eClient.startLlmTrace(featureId = "smoke.android", taskType = "smoke_test", surface = "sdk_checks")
        e2eTrace.submitPrompt(prompt = "Android 스모크 프롬프트", language = "ko")
        e2eTrace.attach("req_smoke_android")
        e2eTrace.markResponseVisible(responseId = "resp_smoke_android", responseText = "Android 응답", timeToVisibleMs = 42)
        e2eTrace.captureOutcome(AbtoResponseInteraction.COPIED, responseId = "resp_smoke_android")

        val done = CountDownLatch(1)
        e2eClient.flush { done.countDown() }
        check(done.await(10, TimeUnit.SECONDS), "e2e flush to local collector completed")
    } else {
        println("skip e2e (set ABTO_E2E=1 with dev collector running)")
    }

    checkConformanceCoverage()


    if (failures > 0) {
        println("$failures check(s) failed")
        exitProcess(1)
    }
    println("all checks passed")
}
