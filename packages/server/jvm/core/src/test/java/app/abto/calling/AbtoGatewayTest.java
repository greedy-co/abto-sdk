package app.abto.calling;

import java.io.IOException;
import java.net.ConnectException;
import java.net.URI;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import static org.junit.jupiter.api.Assertions.*;
import static app.abto.calling.internal.CallingContract.*;

class AbtoGatewayTest {
    static final URI URL = URI.create("https://gateway.example/v1/chat/completions");
    static final String TRACE = "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01";
    record Reply(int status, Map<String, List<String>> headers, String body) {}
    static final Reply OK = new Reply(200, Map.of(HEADER_REQUEST_ID, List.of("request")), "unchanged");
    static final Reply REJECTED = new Reply(503, Map.of(HEADER_REQUEST_ID, List.of("request"), HEADER_ERROR_SOURCE, List.of(ERROR_SOURCE_GATEWAY)), "admission");
    static final AbtoGateway.Response<Reply> RESPONSE = new AbtoGateway.Response<>() {
        public int status(Reply value) { return value.status(); }
        public Map<String, List<String>> headers(Reply value) { return value.headers(); }
        public void discard(Reply value) {}
    };
    static AbtoConfig.Builder config() { return AbtoConfig.builder().environment(k -> null).apiKey("calling-secret").gatewayBaseUrl("https://gateway.example/v1"); }
    static AbtoFallback fallback() { return AbtoFallback.builder().baseUrl("https://direct.example/custom/v1").build(); }
    static AbtoConfig enabled() { return config().providerKey("openai", "provider-secret").fallback(fallback()).build(); }
    static Reply call(AbtoGateway gateway, AbtoGateway.Sender<Reply> sender) throws Exception { return gateway.execute(URL, "POST", Map.of(), sender, RESPONSE); }
    static void error(String message, org.junit.jupiter.api.function.Executable action) { assertEquals(message, assertThrows(IllegalArgumentException.class, action).getMessage()); }

    @Test void validatesEndpointPortsAtConstruction() {
        for (String port : List.of("65536", "2147483647", "2147483648", "-1")) {
            String url = "https://gateway.example:" + port + "/v1";
            error(ERR_GATEWAY_BASE_URL_INVALID, () -> config().gatewayBaseUrl(url).build());
            error(ERR_FALLBACK_BASE_URL_INVALID, () -> AbtoFallback.builder().baseUrl(url).build());
        }
        for (String authority : List.of("gateway.example", "gateway.example:0", "gateway.example:65535")) {
            String url = "https://" + authority + "/v1/";
            assertEquals(URI.create(url), config().gatewayBaseUrl(url).build().gatewayBaseUrl());
            assertEquals(URI.create(url), AbtoFallback.builder().baseUrl(url).build().baseUrl());
        }
    }

    @TestFactory Stream<DynamicTest> coreContractScenarios() {
        var scenarios = new java.util.LinkedHashMap<String, org.junit.jupiter.api.function.Executable>();
        scenarios.put("config.api_key_required", () -> error(ERR_API_KEY_REQUIRED, () -> AbtoConfig.builder().environment(k -> null).gatewayBaseUrl(URL.toString()).build()));
        scenarios.put("config.gateway_base_url_required", () -> error(ERR_GATEWAY_BASE_URL_REQUIRED, () -> AbtoConfig.builder().environment(k -> null).apiKey("test").build()));
        scenarios.put("config.gateway_base_url_from_env", () -> assertEquals("https://gateway.example/v1/", AbtoConfig.builder().environment(k -> k.equals(API_KEY_ENV) ? "key" : "https://gateway.example/v1").build().gatewayBaseUrl().toString()));
        scenarios.put("fallback.destination_required", () -> error(ERR_FALLBACK_BASE_URL_REQUIRED, () -> AbtoFallback.builder().build()));
        scenarios.put("fallback.destination_alone_enables", () -> assertNotNull(enabled().fallback()));
        scenarios.put("fallback.rejected_without_openai_key", () -> error(ERR_FALLBACK_OPENAI_KEY_REQUIRED, () -> config().fallback(fallback()).build()));
        scenarios.put("fallback.off_when_unconfigured", () -> {
            var count = new AtomicInteger();
            assertSame(REJECTED, call(new AbtoGateway(config().build()), d -> { count.incrementAndGet(); return REJECTED; }));
            assertEquals(1, count.get());
        });
        scenarios.put("fallback.timeout_validated", () -> {
            for (Duration value : List.of(Duration.ZERO, Duration.ofMillis(-1))) error(ERR_FALLBACK_TIMEOUT_POSITIVE, () -> AbtoFallback.builder().baseUrl("https://direct.example").timeout(value).build());
        });
        scenarios.put("fallback.switches_on_connect_failure", () -> {
            var calls = new ArrayList<URI>();
            assertSame(OK, call(new AbtoGateway(enabled()), d -> { calls.add(d.uri()); if (calls.size() == 1) throw new ConnectException(); return OK; }));
            assertEquals(List.of(URL, fallback().baseUrl().resolve(DIRECT_PATH_SUFFIX)), calls);
        });
        scenarios.put("fallback.switches_on_admission_503", () -> {
            var calls = new AtomicInteger();
            assertSame(OK, call(new AbtoGateway(enabled()), d -> calls.incrementAndGet() == 1 ? REJECTED : OK)); assertEquals(2, calls.get());
        });
        scenarios.put("fallback.no_switch_on_ambiguous_timeout", () -> ambiguous(new HttpTimeoutException("timeout")));
        scenarios.put("fallback.no_switch_on_ambiguous_disconnect", () -> ambiguous(new IOException("connection reset")));
        scenarios.put("fallback.replays_timeout_when_opted_in", () -> {
            var gateway = new AbtoGateway(config().providerKey("openai", "key").fallback(AbtoFallback.builder().baseUrl("https://direct.example/v1").onTimeout(true).build()).build());
            var count = new AtomicInteger();
            assertSame(OK, call(gateway, d -> { if (count.incrementAndGet() == 1) throw new HttpTimeoutException("timeout"); return OK; }));
            assertEquals(2, count.get());
        });
        scenarios.put("fallback.sends_to_configured_destination", () -> {
            var calls = new ArrayList<URI>();
            call(new AbtoGateway(enabled()), d -> { calls.add(d.uri()); return calls.size() == 1 ? REJECTED : OK; });
            assertEquals(URI.create("https://direct.example/custom/v1/chat/completions"), calls.get(1));
        });
        scenarios.put("fallback.direct_error_returned_as_is", () -> {
            var direct = new Reply(429, Map.of("retry-after", List.of("3")), "original-error");
            assertSame(direct, call(new AbtoGateway(enabled()), d -> d.uri().equals(URL) ? REJECTED : direct));
        });
        scenarios.put("security.rejects_cross_origin_request", () -> error(ERR_GATEWAY_ORIGIN_REFUSED, () -> new AbtoGateway(enabled()).execute(URI.create("https://attacker.example/v1/chat/completions"), "POST", Map.of(), d -> fail("must not dispatch"), RESPONSE)));
        scenarios.put("security.replaces_spoofed_context_headers", () -> new AbtoGateway(enabled()).forContext(AbtoContext.builder("feature").nodeId("node").deviceId("device").build()).execute(URL, "POST", Map.of(HEADER_FEATURE_ID, List.of("spoof"), HEADER_NODE_ID, List.of("spoof"), HEADER_DEVICE_ID, List.of("spoof"), HEADER_PROVIDER_KEY_PREFIX + "unknown", List.of("spoof")), d -> {
            assertEquals(List.of("feature"), d.headers().get(HEADER_FEATURE_ID)); assertEquals(List.of("node"), d.headers().get(HEADER_NODE_ID)); assertEquals(List.of("device"), d.headers().get(HEADER_DEVICE_ID)); assertFalse(d.headers().containsValue(List.of("spoof"))); return OK;
        }, RESPONSE));
        scenarios.put("security.rejects_provider_key_injection", () -> error(ERR_PROVIDER_KEY_INVALID_CHARACTERS.replace("{provider}", "openai"), () -> call(new AbtoGateway(config().providerKey("openai", "x\r\nInjected: value").build()), d -> fail("must not dispatch"))));
        scenarios.put("context.propagates_and_isolates", () -> {
            var gateway = new AbtoGateway(enabled());
            var futures = new ArrayList<CompletableFuture<Reply>>();
            for (int i = 0; i < 100; i++) {
                String feature = "feature-" + i;
                futures.add(CompletableFuture.supplyAsync(() -> {
                    try { return call(gateway.forContext(AbtoContext.of(feature)), d -> { assertEquals(List.of(feature), d.headers().get(HEADER_FEATURE_ID)); return OK; }); }
                    catch (Exception e) { throw new RuntimeException(e); }
                }));
            }
            CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).join();
        });
        scenarios.put("context.emits_only_configured_identifiers", () -> call(new AbtoGateway(enabled()).forContext(AbtoContext.of("feature")), d -> {
            assertFalse(d.headers().containsKey(HEADER_DEVICE_ID)); assertFalse(d.headers().containsKey(HEADER_NODE_ID)); assertFalse(d.headers().containsKey(HEADER_REQUEST_ID)); assertFalse(d.headers().containsKey("traceparent")); return OK;
        }));
        scenarios.put("circuit.shared_across_clients", () -> {
            var gateway = new AbtoGateway(enabled());
            call(gateway.forContext(AbtoContext.of("a")), d -> d.uri().equals(URL) ? REJECTED : OK);
            call(gateway.forContext(AbtoContext.of("b")), d -> { assertNotEquals(URL, d.uri()); return OK; });
        });
        scenarios.put("circuit.closes_on_gateway_recovery", () -> {
            var clock = new AtomicLong(); var gateway = new AbtoGateway(enabled(), clock::get);
            call(gateway, d -> d.uri().equals(URL) ? REJECTED : OK);
            clock.addAndGet(Duration.ofMillis(CIRCUIT_OPEN_MS).toNanos());
            for (int i = 0; i < 2; i++) call(gateway, d -> { assertEquals(URL, d.uri()); return OK; });
        });
        scenarios.put("provider_key.resolved_per_request", () -> {
            var value = new AtomicInteger(); var gateway = new AbtoGateway(config().providerKey("openai", () -> "key-" + value.incrementAndGet()).build());
            for (int i = 1; i <= 2; i++) { String expected = "key-" + i; call(gateway, d -> { assertEquals(List.of(expected), d.headers().get(HEADER_PROVIDER_KEY_PREFIX + "openai")); return OK; }); }
        });
        // Retry scenarios run against the official OpenAI client in the calling module.
        Set<String> expected = new HashSet<>(CONFORMANCE_SCENARIOS);
        expected.removeAll(Set.of("retry.official_default_preserved", "retry.caller_setting_preserved"));
        assertEquals(expected, scenarios.keySet(), "Update JVM conformance tests when the shared contract changes.");
        return scenarios.entrySet().stream().map(e -> DynamicTest.dynamicTest(e.getKey(), e.getValue()));
    }

    private static void ambiguous(Exception failure) {
        var count = new AtomicInteger();
        assertSame(failure, assertThrows(Exception.class, () -> call(new AbtoGateway(enabled()), d -> { count.incrementAndGet(); throw failure; })));
        assertEquals(1, count.get());
    }

    @Test void contextRejectsMissingFeatureAndBlankNode() {
        assertThrows(IllegalArgumentException.class, () -> AbtoContext.of(null));
        assertThrows(IllegalArgumentException.class, () -> AbtoContext.of(" "));
        assertThrows(IllegalArgumentException.class, () -> AbtoContext.builder("feature").nodeId("").build());
        assertThrows(IllegalArgumentException.class, () -> AbtoContext.builder("feature").nodeId("a\r\nInjected: b").build());
    }

    @Test void directDispatchRemovesCredentialsAndPreservesTracing() throws Exception {
        var headers = Map.of("Cookie", List.of("session=secret"), "Proxy-Authorization", List.of("secret"), "Authorization", List.of("old-key"), "traceparent", List.of(TRACE), "tracestate", List.of("vendor=value"), "X-Custom-Secret", List.of("secret"));
        new AbtoGateway(enabled()).forContext(AbtoContext.builder("f").nodeId("n").deviceId("d").traceparent("replacement").tracestate("replacement").build()).execute(URL, "POST", headers, dispatch -> {
            if (dispatch.uri().equals(URL)) return REJECTED;
            assertEquals(Set.of("authorization", "traceparent", "tracestate"), dispatch.headers().keySet());
            assertEquals(List.of("Bearer provider-secret"), dispatch.headers().get("authorization"));
            assertEquals(List.of(TRACE), dispatch.headers().get("traceparent"));
            assertEquals(List.of("vendor=value"), dispatch.headers().get("tracestate"));
            assertFalse(dispatch.toString().contains("secret")); return OK;
        }, RESPONSE);
    }

    @Test void providerAndTransportErrorsNeverFallBack() throws Exception {
        for (String source : List.of(ERROR_SOURCE_PROVIDER, ERROR_SOURCE_TRANSPORT)) {
            for (int status : List.of(400, 429, 500, 502, 503, 504)) {
                var response = new Reply(status, Map.of(HEADER_REQUEST_ID, List.of("request"), HEADER_ERROR_SOURCE, List.of(source)), "error");
                var count = new AtomicInteger();
                assertSame(response, call(new AbtoGateway(enabled()), d -> { count.incrementAndGet(); return response; })); assertEquals(1, count.get());
            }
        }
    }

    @Test void cancelledProbeReleasesCircuitAndCancelsDelegate() throws Exception {
        var clock = new AtomicLong(); var gateway = new AbtoGateway(enabled(), clock::get);
        call(gateway, d -> d.uri().equals(URL) ? REJECTED : OK);
        clock.addAndGet(Duration.ofMillis(CIRCUIT_OPEN_MS).toNanos());
        var pending = new CompletableFuture<Reply>();
        var future = gateway.executeAsync(URL, "POST", Map.of(), d -> { assertEquals(URL, d.uri()); return pending; }, RESPONSE);
        call(gateway, d -> { assertNotEquals(URL, d.uri()); return OK; });
        assertTrue(future.cancel(true)); assertTrue(pending.isCancelled());
        call(gateway, d -> { assertEquals(URL, d.uri()); return OK; });
    }

    @Test void failedAndThrowingAsyncProbesReleaseCircuit() throws Exception {
        var clock = new AtomicLong(); var gateway = new AbtoGateway(enabled(), clock::get);
        call(gateway, d -> d.uri().equals(URL) ? REJECTED : OK);
        clock.addAndGet(Duration.ofMillis(CIRCUIT_OPEN_MS).toNanos());
        for (int i = 0; i < 2; i++) {
            assertThrows(java.util.concurrent.CompletionException.class, () -> gateway.executeAsync(URL, "POST", Map.of(), d -> {
                assertEquals(URL, d.uri()); throw new IllegalStateException("transport failure");
            }, RESPONSE).join());
        }
        call(gateway, d -> { assertEquals(URL, d.uri()); return OK; });
    }

    @Test void asyncFallbackReturnsOriginalDirectResponse() {
        var calls = new AtomicInteger();
        assertSame(OK, new AbtoGateway(enabled()).executeAsync(URL, "POST", Map.of(), d -> CompletableFuture.completedFuture(calls.incrementAndGet() == 1 ? REJECTED : OK), RESPONSE).join());
        assertEquals(2, calls.get());
    }

    @Test void explicitCancellationStopsDependentFutureAndPreventsFurtherDispatch() {
        var cancellation = new AbtoCancellation();
        var pending = new CompletableFuture<Reply>();
        var gateway = new AbtoGateway(enabled()).withCancellation(cancellation);
        var response = gateway.executeAsync(URL, "POST", Map.of(), dispatch -> pending, RESPONSE);
        var dependent = cancellation.bind(response.thenApply(Reply::body));
        dependent.cancel(true);
        assertTrue(response.isCancelled()); assertTrue(pending.isCancelled());
        assertThrows(java.util.concurrent.CancellationException.class, () -> gateway.executeAsync(URL, "POST", Map.of(), dispatch -> fail("cancelled scope must not dispatch"), RESPONSE).join());
    }
}
