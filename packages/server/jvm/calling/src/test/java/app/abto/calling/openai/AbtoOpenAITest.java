package app.abto.calling.openai;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoFallback;
import com.openai.client.OpenAIClient;
import com.openai.client.OpenAIClientImpl;
import com.openai.core.ClientOptions;
import com.openai.core.JsonValue;
import com.openai.core.RequestOptions;
import com.openai.core.Sleeper;
import com.openai.core.http.Headers;
import com.openai.core.http.HttpClient;
import com.openai.core.http.HttpRequest;
import com.openai.core.http.HttpResponse;
import com.openai.models.chat.completions.ChatCompletionCreateParams;
import com.openai.models.responses.ResponseCreateParams;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.stream.Stream;
import org.junit.jupiter.api.DynamicTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import static org.junit.jupiter.api.Assertions.*;
import static app.abto.calling.internal.CallingContract.*;

class AbtoOpenAITest {
    static final String COMPLETION = "{\"id\":\"chat-test\",\"object\":\"chat.completion\",\"created\":1,\"model\":\"gateway-selected-model\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"hello\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":2,\"completion_tokens\":1,\"total_tokens\":3}}";
    static AbtoConfig config(boolean fallback) {
        return AbtoConfig.builder().environment(k -> null).apiKey("calling-secret").gatewayBaseUrl("https://gateway.example/v1")
                .providerKey("openai", "provider-secret").fallback(fallback ? AbtoFallback.builder().baseUrl("https://direct.example/v1").build() : null).build();
    }
    static ChatCompletionCreateParams params() {
        return ChatCompletionCreateParams.builder().model("original-model").addUserMessage("hello").temperature(0.3)
                .putAdditionalBodyProperty("custom_parameter", JsonValue.from("keep")).build();
    }
    static OpenAIClient seed(Stub transport, Consumer<ClientOptions.Builder> options) {
        var builder = ClientOptions.builder().httpClient(transport).apiKey("old-key").baseUrl("https://old.example/v1").sleeper(new NoWait());
        options.accept(builder);
        return new OpenAIClientImpl(builder.build());
    }
    static Reply ok() { return new Reply(200, Map.of(HEADER_REQUEST_ID, "gateway-request", "x-custom", "preserved"), COMPLETION); }
    static Reply rejected() { return new Reply(503, Map.of(HEADER_REQUEST_ID, "admission", HEADER_ERROR_SOURCE, ERROR_SOURCE_GATEWAY), "{\"error\":{\"message\":\"unavailable\"}}"); }

    @Test void factoryAndConfigKeepNativeBodyAndReturnRawResponse() throws Exception {
        var bodies = new ArrayList<String>();
        for (boolean factory : List.of(true, false)) {
            var stub = new Stub(request -> {
                assertEquals("https://gateway.example/v1/chat/completions", request.url());
                assertEquals(List.of("Bearer calling-secret"), request.headers().values("authorization"));
                assertEquals(List.of("provider-secret"), request.headers().values(HEADER_PROVIDER_KEY_PREFIX + "openai"));
                assertEquals(List.of("feature"), request.headers().values(HEADER_FEATURE_ID));
                var body = new ByteArrayOutputStream(); request.body().writeTo(body); bodies.add(body.toString(StandardCharsets.UTF_8));
                return ok();
            });
            var original = seed(stub, b -> b.timeout(Duration.ofSeconds(7)).maxRetries(4));
            try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(false), original, stub.jdk)) {
                var scope = abto.forContext(AbtoContext.builder("feature").deviceId("device").build());
                var client = factory ? scope.openai() : original.withOptions(scope.openaiOptions(stub.jdk));
                client.withOptions(b -> {
                    var options = b.build();
                    assertEquals(4, options.maxRetries()); assertEquals(Duration.ofSeconds(7), options.timeout().request());
                    assertEquals(AbtoConfig.AUTH_PLACEHOLDER, options.apiKey().orElseThrow());
                });
                try (var response = client.chat().completions().withRawResponse().create(params())) {
                    assertEquals(200, response.statusCode()); assertEquals(List.of("preserved"), response.headers().values("x-custom"));
                    assertEquals("gateway-selected-model", response.parse().model());
                }
                client.close(); assertEquals(0, stub.closed.get());
            }
            assertEquals(1, stub.closed.get());
        }
        assertEquals(bodies.get(0), bodies.get(1));
        assertTrue(bodies.get(0).contains("original-model")); assertTrue(bodies.get(0).contains("custom_parameter"));
    }

    @Test void preservesTypedToolRoundTripAndStructuredOutput() throws Exception {
        var bodies = new ArrayList<String>();
        var mapper = new com.fasterxml.jackson.databind.ObjectMapper();
        var stub = new Stub(request -> {
            var output = new ByteArrayOutputStream(); request.body().writeTo(output);
            bodies.add(output.toString(StandardCharsets.UTF_8));
            if (bodies.size() == 1) return new Reply(200, Map.of(), """
                    {"id":"tool-turn","object":"chat.completion","created":1,"model":"gateway-model",
                     "choices":[{"index":0,"finish_reason":"tool_calls","message":{"role":"assistant","content":null,
                     "tool_calls":[{"id":"call_weather","type":"function","function":{"name":"weather","arguments":"{}"}}]}}]}
                    """);
            if (bodies.size() == 3) {
                return new Reply(200, Map.of(), COMPLETION.replace("\"content\":\"hello\"", "\"content\":\"{\\\"answer\\\":\\\"Sunny\\\"}\""));
            }
            return ok();
        });
        try (var abto = AbtoOpenAI.create(config(false), stub.jdk)) {
            var client = abto.forContext(AbtoContext.of("tools")).openai();
            var request = ChatCompletionCreateParams.builder().model("customer-model").addUserMessage("Weather?")
                    .addTool(com.openai.models.chat.completions.ChatCompletionFunctionTool.builder()
                            .function(com.openai.models.FunctionDefinition.builder().name("weather")
                                    .parameters(com.openai.models.FunctionParameters.builder()
                                            .putAdditionalProperty("type", JsonValue.from("object"))
                                            .putAdditionalProperty("properties", JsonValue.from(Map.of())).build()).build()).build()).build();
            var assistant = client.chat().completions().create(request).choices().get(0).message();
            assertEquals("weather", assistant.toolCalls().orElseThrow().get(0).asFunction().function().name());
            client.chat().completions().create(request.toBuilder().addMessage(assistant)
                    .addMessage(com.openai.models.chat.completions.ChatCompletionToolMessageParam.builder()
                            .toolCallId("call_weather").content("Sunny").build()).build());
            var structured = client.chat().completions().create(params().toBuilder().responseFormat(com.openai.models.ResponseFormatJsonSchema.builder()
                    .jsonSchema(com.openai.models.ResponseFormatJsonSchema.JsonSchema.builder().name("answer").strict(true)
                            .schema(com.openai.models.ResponseFormatJsonSchema.JsonSchema.Schema.builder()
                                    .putAdditionalProperty("type", JsonValue.from("object"))
                                    .putAdditionalProperty("properties", JsonValue.from(Map.of("answer", Map.of("type", "string"))))
                                    .putAdditionalProperty("required", JsonValue.from(List.of("answer")))
                                    .putAdditionalProperty("additionalProperties", JsonValue.from(false)).build()).build()).build()).build());
            assertEquals("Sunny", mapper.readTree(structured.choices().get(0).message().content().orElseThrow()).get("answer").asText());
            assertEquals("weather", mapper.readTree(bodies.get(0)).at("/tools/0/function/name").asText());
            assertEquals("call_weather", mapper.readTree(bodies.get(1)).at("/messages/2/tool_call_id").asText());
            assertEquals("Sunny", mapper.readTree(bodies.get(1)).at("/messages/2/content").asText());
            assertTrue(mapper.readTree(bodies.get(2)).at("/response_format/json_schema/strict").asBoolean());
            assertEquals("json_schema", mapper.readTree(bodies.get(2)).at("/response_format/type").asText());
        }
    }

    @TestFactory Stream<DynamicTest> retryContractScenarios() {
        return Map.of("retry.official_default_preserved", 2, "retry.caller_setting_preserved", 4).entrySet().stream().map(entry -> DynamicTest.dynamicTest(entry.getKey(), () -> {
            assertTrue(CONFORMANCE_SCENARIOS.contains(entry.getKey()));
            for (boolean factory : List.of(true, false)) {
                var calls = new AtomicInteger();
                var stub = new Stub(request -> calls.getAndIncrement() < entry.getValue()
                        ? new Reply(429, Map.of("retry-after-ms", "1", HEADER_ERROR_SOURCE, ERROR_SOURCE_PROVIDER, HEADER_REQUEST_ID, "executed"), "{\"error\":{\"message\":\"rate limited\"}}") : ok());
                var original = seed(stub, b -> { if (entry.getValue() != 2) b.maxRetries(entry.getValue()); });
                try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(true), original, stub.jdk)) {
                    var client = factory ? abto.openai() : original.withOptions(abto.openaiOptions(stub.jdk));
                    assertEquals("chat-test", client.chat().completions().create(params()).id());
                    assertEquals(entry.getValue() + 1, calls.get());
                }
            }
        }));
    }

    @Test void fallbackSharesCircuitAcrossFactoryAndConfigAndKeepsBody() throws Exception {
        var urls = new CopyOnWriteArrayList<String>();
        var bodies = new CopyOnWriteArrayList<String>();
        var stub = new Stub(request -> {
            urls.add(request.url());
            var body = new ByteArrayOutputStream(); request.body().writeTo(body); bodies.add(body.toString(StandardCharsets.UTF_8));
            if (request.url().startsWith("https://gateway.example/")) return rejected();
            assertEquals(List.of("Bearer provider-secret"), request.headers().values("authorization"));
            assertTrue(request.headers().names().stream().noneMatch(n -> n.startsWith("x-abto-")));
            assertTrue(request.headers().values("cookie").isEmpty()); return ok();
        });
        var original = seed(stub, b -> b.putHeader("Cookie", "secret-cookie"));
        try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(true), original, stub.jdk)) {
            abto.forContext(AbtoContext.of("first")).openai().chat().completions().create(params());
            original.withOptions(abto.forContext(AbtoContext.of("second")).openaiOptions(stub.jdk)).async().chat().completions().create(params()).join();
            assertEquals(List.of("https://gateway.example/v1/chat/completions", "https://direct.example/v1/chat/completions", "https://direct.example/v1/chat/completions"), urls);
            assertEquals(1, bodies.stream().distinct().count());
        }
    }

    @Test void responsesRequestFallsBackToTheSamePathWithItsBodyUnchanged() throws Exception {
        var urls = new CopyOnWriteArrayList<String>();
        var bodies = new CopyOnWriteArrayList<String>();
        var stub = new Stub(request -> {
            urls.add(request.url());
            var body = new ByteArrayOutputStream(); request.body().writeTo(body); bodies.add(body.toString(StandardCharsets.UTF_8));
            return request.url().startsWith("https://gateway.example/") ? rejected()
                    : new Reply(200, Map.of(), "{\"id\":\"resp-test\",\"object\":\"response\",\"created_at\":1,\"model\":\"original-model\",\"output\":[]}");
        });
        var original = seed(stub, b -> {});
        try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(true), original, stub.jdk)) {
            var params = ResponseCreateParams.builder().model("original-model").input("hello").build();
            assertEquals("resp-test", abto.forContext(AbtoContext.of("feature")).openai().responses().create(params).id());
            assertEquals(List.of("https://gateway.example/v1/responses", "https://direct.example/v1/responses"), urls);
            assertEquals(1, bodies.stream().distinct().count());
        }
    }

    @Test void asynchronousContextsStayIsolatedAndBorrowedResourcesStayOpen() throws Exception {
        var contexts = new CopyOnWriteArrayList<String>();
        var executor = Executors.newSingleThreadExecutor();
        var sleeper = new NoWait();
        var stub = new Stub(request -> { contexts.add(request.headers().values(HEADER_FEATURE_ID).get(0)); return ok(); });
        var original = seed(stub, b -> b.streamHandlerExecutor(executor).sleeper(sleeper));
        try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(false), original, stub.jdk)) {
            var futures = new ArrayList<CompletableFuture<?>>();
            for (int i = 0; i < 40; i++) {
                var client = abto.forContext(AbtoContext.of("feature-" + i)).openai();
                futures.add(client.async().chat().completions().create(params()));
                client.close();
            }
            CompletableFuture.allOf(futures.toArray(CompletableFuture[]::new)).join();
            assertEquals(40, contexts.stream().distinct().count());
            assertFalse(executor.isShutdown()); assertEquals(0, sleeper.closed.get()); assertEquals(0, stub.closed.get());
        } finally { executor.shutdownNow(); }
        assertTrue(sleeper.closed.get() > 0); assertEquals(1, stub.closed.get());
    }

    static class Stub implements HttpClient {
        final Function<HttpRequest, HttpResponse> send;
        final java.net.http.HttpClient jdk = new SafeStub(this);
        final AtomicInteger closed = new AtomicInteger();
        Stub(Function<HttpRequest, HttpResponse> send) { this.send = send; }
        public HttpResponse execute(HttpRequest request, RequestOptions options) { return send.apply(request); }
        public HttpResponse execute(HttpRequest request) { return execute(request, RequestOptions.none()); }
        public CompletableFuture<HttpResponse> executeAsync(HttpRequest request, RequestOptions options) {
            try { return CompletableFuture.completedFuture(execute(request, options)); }
            catch (Exception error) { return CompletableFuture.failedFuture(error); }
        }
        public CompletableFuture<HttpResponse> executeAsync(HttpRequest request) { return executeAsync(request, RequestOptions.none()); }
        public void close() { closed.incrementAndGet(); }
    }

    @Test void cancellationHandleBridgesOfficialFutureToActualHttpCall() throws Exception {
        var cancellation = new app.abto.calling.AbtoCancellation();
        var arrived = new java.util.concurrent.CountDownLatch(1);
        var active = new CompletableFuture<java.net.http.HttpResponse<byte[]>>();
        var transport = new SafeStub(new Stub(request -> fail("cancelled request must not fall back"))) {
            @SuppressWarnings("unchecked")
            @Override public <T> CompletableFuture<java.net.http.HttpResponse<T>> sendAsync(java.net.http.HttpRequest request, java.net.http.HttpResponse.BodyHandler<T> handler) {
                arrived.countDown();
                return (CompletableFuture<java.net.http.HttpResponse<T>>) (CompletableFuture<?>) active;
            }
        };
        try (var abto = AbtoOpenAI.create(config(true), transport)) {
            var client = abto.forContext(AbtoContext.of("cancel-me")).withCancellation(cancellation).openai();
            var future = cancellation.bind(client.async().chat().completions().create(params()));
            assertTrue(arrived.await(5, java.util.concurrent.TimeUnit.SECONDS));
            assertTrue(future.cancel(true));
            assertTrue(active.isCancelled());
            assertTrue(cancellation.isCancelled());
        }
    }

    @Test void unsafeExplicitTransportFailsBeforeOptionsAreApplied() {
        try (var abto = AbtoOpenAI.create(config(false))) {
            assertThrows(IllegalArgumentException.class, () -> abto.openaiOptions(java.net.http.HttpClient.newBuilder().followRedirects(java.net.http.HttpClient.Redirect.ALWAYS).build()));
        }
    }

    @Test void rejectsUnsupportedPhaseTimeoutsInsteadOfSilentlyDroppingThem() throws Exception {
        var stub = new Stub(request -> fail("unsupported timeout must fail before dispatch"));
        var original = seed(stub, builder -> builder.timeout(com.openai.core.Timeout.builder()
                .request(Duration.ofSeconds(20)).read(Duration.ofSeconds(2)).build()));
        try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(false), original, stub.jdk)) {
            assertThrows(IllegalArgumentException.class, abto::openai);
        }
        JdkOpenAIHttpClient.validateTimeout(com.openai.core.Timeout.builder().request(Duration.ofSeconds(7)).build(), stub.jdk);
        assertThrows(IllegalArgumentException.class, () -> JdkOpenAIHttpClient.validateTimeout(
                com.openai.core.Timeout.builder().connect(Duration.ofSeconds(2)).build(), stub.jdk));
    }

    @Test void transportIoRetryBehaviorMatchesOfficialClient() throws Exception {
        for (boolean asynchronous : List.of(false, true)) {
            var baselineCount = new AtomicInteger();
            var baselineStub = new Stub(request -> {
                if (baselineCount.incrementAndGet() < 3) throw new com.openai.errors.OpenAIIoException("HTTP request failed", new java.io.IOException("connection reset"));
                return ok();
            });
            var baseline = seed(baselineStub, builder -> {});
            boolean expectedSuccess;
            try { expectedSuccess = succeeds(baseline, asynchronous); } finally { baseline.close(); }
            var count = new AtomicInteger();
            var stub = new Stub(request -> ok());
            var transport = new SafeStub(stub) {
                @Override public <T> java.net.http.HttpResponse<T> send(java.net.http.HttpRequest request, java.net.http.HttpResponse.BodyHandler<T> handler) throws java.io.IOException {
                    if (count.incrementAndGet() < 3) throw new java.io.IOException("connection reset");
                    return super.send(request, handler);
                }
            };
            var original = seed(stub, builder -> {});
            try (AutoCloseable ignored = original::close; var abto = AbtoOpenAI.create(config(false), original, transport)) {
                var client = abto.openai();
                assertEquals(expectedSuccess, succeeds(client, asynchronous));
                assertEquals(baselineCount.get(), count.get(), "ABTO must preserve the official SDK's retry behavior, including upstream limitations.");
            }
        }
    }
    static boolean succeeds(OpenAIClient client, boolean asynchronous) {
        try {
            String id = asynchronous ? client.async().chat().completions().create(params()).join().id() : client.chat().completions().create(params()).id();
            assertEquals("chat-test", id); return true;
        } catch (com.openai.errors.OpenAIIoException | java.util.concurrent.CompletionException error) { return false; }
    }

    static class SafeStub extends java.net.http.HttpClient {
        final Stub delegate;
        SafeStub(Stub delegate) { this.delegate = delegate; }
        @Override public <T> java.net.http.HttpResponse<T> send(java.net.http.HttpRequest request, java.net.http.HttpResponse.BodyHandler<T> handler) throws java.io.IOException {
            var body = new ByteArrayOutputStream();
            var done = new CompletableFuture<Void>();
            request.bodyPublisher().orElseThrow().subscribe(new java.util.concurrent.Flow.Subscriber<>() {
                public void onSubscribe(java.util.concurrent.Flow.Subscription subscription) { subscription.request(Long.MAX_VALUE); }
                public void onNext(java.nio.ByteBuffer buffer) { byte[] bytes = new byte[buffer.remaining()]; buffer.get(bytes); body.writeBytes(bytes); }
                public void onError(Throwable error) { done.completeExceptionally(error); }
                public void onComplete() { done.complete(null); }
            });
            done.join();
            var headers = Headers.builder(); request.headers().map().forEach(headers::put);
            var original = HttpRequest.builder().baseUrl(request.uri().toString()).method(com.openai.core.http.HttpMethod.valueOf(request.method())).headers(headers.build())
                    .body(new com.openai.core.http.HttpRequestBody() {
                        public void writeTo(java.io.OutputStream output) { try { output.write(body.toByteArray()); } catch (java.io.IOException error) { throw new java.io.UncheckedIOException(error); } }
                        public String contentType() { return "application/json"; }
                        public long contentLength() { return body.size(); }
                        public boolean repeatable() { return true; }
                        public void close() {}
                    }).build();
            HttpResponse response = delegate.send.apply(original);
            var mapped = new java.util.LinkedHashMap<String, List<String>>(); response.headers().names().forEach(n -> mapped.put(n, response.headers().values(n)));
            var responseHeaders = java.net.http.HttpHeaders.of(mapped, (k, v) -> true);
            var subscriber = handler.apply(new java.net.http.HttpResponse.ResponseInfo() {
                public int statusCode() { return response.statusCode(); }
                public java.net.http.HttpHeaders headers() { return responseHeaders; }
                public Version version() { return Version.HTTP_1_1; }
            });
            byte[] bytes = response.body().readAllBytes(); response.close();
            subscriber.onSubscribe(new java.util.concurrent.Flow.Subscription() { public void request(long n) {} public void cancel() {} });
            subscriber.onNext(List.of(java.nio.ByteBuffer.wrap(bytes))); subscriber.onComplete();
            T result = subscriber.getBody().toCompletableFuture().join();
            return new java.net.http.HttpResponse<>() {
                public int statusCode() { return response.statusCode(); }
                public java.net.http.HttpRequest request() { return request; }
                public java.util.Optional<java.net.http.HttpResponse<T>> previousResponse() { return java.util.Optional.empty(); }
                public java.net.http.HttpHeaders headers() { return responseHeaders; }
                public T body() { return result; }
                public java.util.Optional<javax.net.ssl.SSLSession> sslSession() { return java.util.Optional.empty(); }
                public java.net.URI uri() { return request.uri(); }
                public Version version() { return Version.HTTP_1_1; }
            };
        }
        @Override public <T> CompletableFuture<java.net.http.HttpResponse<T>> sendAsync(java.net.http.HttpRequest request, java.net.http.HttpResponse.BodyHandler<T> handler) {
            try { return CompletableFuture.completedFuture(send(request, handler)); } catch (Exception error) { return CompletableFuture.failedFuture(error); }
        }
        @Override public <T> CompletableFuture<java.net.http.HttpResponse<T>> sendAsync(java.net.http.HttpRequest request, java.net.http.HttpResponse.BodyHandler<T> handler, java.net.http.HttpResponse.PushPromiseHandler<T> push) { return sendAsync(request, handler); }
        @Override public java.util.Optional<java.net.CookieHandler> cookieHandler() { return java.util.Optional.empty(); }
        @Override public java.util.Optional<Duration> connectTimeout() { return java.util.Optional.empty(); }
        @Override public Redirect followRedirects() { return Redirect.NEVER; }
        @Override public java.util.Optional<java.net.ProxySelector> proxy() { return java.util.Optional.empty(); }
        @Override public javax.net.ssl.SSLContext sslContext() { try { return javax.net.ssl.SSLContext.getDefault(); } catch (java.security.NoSuchAlgorithmException error) { throw new IllegalStateException(error); } }
        @Override public javax.net.ssl.SSLParameters sslParameters() { return new javax.net.ssl.SSLParameters(); }
        @Override public java.util.Optional<java.net.Authenticator> authenticator() { return java.util.Optional.empty(); }
        @Override public Version version() { return Version.HTTP_1_1; }
        @Override public java.util.Optional<java.util.concurrent.Executor> executor() { return java.util.Optional.empty(); }
    }

    static class NoWait implements Sleeper {
        final AtomicInteger closed = new AtomicInteger();
        public void sleep(Duration duration) {}
        public CompletableFuture<Void> sleepAsync(Duration duration) { return CompletableFuture.completedFuture(null); }
        public void close() { closed.incrementAndGet(); }
    }
    static class Reply implements HttpResponse {
        final int status;
        final Headers headers;
        final InputStream body;
        Reply(int status, Map<String, String> headers, String body) {
            this.status = status;
            var builder = Headers.builder(); headers.forEach(builder::put); this.headers = builder.build();
            this.body = new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8));
        }
        public int statusCode() { return status; }
        public Headers headers() { return headers; }
        public InputStream body() { return body; }
        public java.util.Optional<String> requestId() { return java.util.Optional.empty(); }
        public void close() { try { body.close(); } catch (java.io.IOException error) { throw new RuntimeException(error); } }
    }
}
