package app.abto.calling.springai2;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import com.sun.net.httpserver.HttpServer;
import io.micrometer.observation.ObservationRegistry;
import io.micrometer.tracing.handler.DefaultTracingObservationHandler;
import io.micrometer.tracing.otel.bridge.OtelCurrentTraceContext;
import io.micrometer.tracing.otel.bridge.OtelTracer;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.data.SpanData;
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor;
import io.opentelemetry.sdk.trace.export.SpanExporter;
import io.opentelemetry.exporter.otlp.http.trace.OtlpHttpSpanExporter;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.Collection;
import java.util.concurrent.CopyOnWriteArrayList;
import org.junit.jupiter.api.Test;
import org.springframework.ai.openai.OpenAiChatModel;
import static org.junit.jupiter.api.Assertions.*;

class TracingCompatibilityTest {
    @Test void keepsExistingMicrometerOtelExporterTraceAndCredentialsPrivate() throws Exception {
        var payloads = new CopyOnWriteArrayList<String>();
        var traceHeaders = new CopyOnWriteArrayList<String>();
        var spans = new CopyOnWriteArrayList<SpanData>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        String base = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/v1/traces", exchange -> {
            payloads.add(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.ISO_8859_1));
            exchange.getResponseHeaders().add("Content-Type", "application/x-protobuf");
            exchange.sendResponseHeaders(200, -1); exchange.close();
        });
        server.createContext("/v1/chat/completions", exchange -> {
            exchange.getRequestBody().readAllBytes();
            traceHeaders.add(exchange.getRequestHeaders().getFirst("traceparent"));
            byte[] result = """
                    {"id":"traced","object":"chat.completion","created":1,"model":"selected",
                    "choices":[{"index":0,"message":{"role":"assistant","content":"hello"},"finish_reason":"stop"}],
                    "usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}
                    """.getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(200, result.length);
            try (var output = exchange.getResponseBody()) { output.write(result); }
        });
        server.start();
        var exporter = OtlpHttpSpanExporter.builder().setEndpoint(base + "/v1/traces").build();
        var capture = new SpanExporter() {
            public CompletableResultCode export(Collection<SpanData> values) { spans.addAll(values); return exporter.export(values); }
            public CompletableResultCode flush() { return exporter.flush(); }
            public CompletableResultCode shutdown() { return exporter.shutdown(); }
        };
        try (var provider = SdkTracerProvider.builder().addSpanProcessor(SimpleSpanProcessor.create(capture)).build()) {
            var otel = OpenTelemetrySdk.builder().setTracerProvider(provider).build();
            var tracer = otel.getTracer("customer-existing-tracer");
            var bridge = new OtelTracer(tracer, new OtelCurrentTraceContext(), event -> {});
            var registry = ObservationRegistry.create();
            registry.observationConfig().observationHandler(new DefaultTracingObservationHandler(bridge));
            var parent = tracer.spanBuilder("customer-request").startSpan();
            String traceparent = "00-" + parent.getSpanContext().getTraceId() + "-" + parent.getSpanContext().getSpanId() + "-01";
            var config = AbtoConfig.builder().environment(key -> null).gatewayBaseUrl(base + "/v1")
                    .apiKey("calling-sensitive-value").providerKey("openai", "provider-sensitive-value").build();
            try (var scope = parent.makeCurrent(); var abto = AbtoSpringAI2.create(config)) {
                var builder = OpenAiChatModel.builder().observationRegistry(registry);
                abto.forContext(AbtoContext.builder("traced").deviceId("device").traceparent(traceparent).tracestate("vendor=value").build()).chatModelOptions().accept(builder);
                assertEquals("hello", builder.build().call("hello"));
            } finally { parent.end(); }
            provider.forceFlush().join(5, java.util.concurrent.TimeUnit.SECONDS);
            assertEquals(java.util.List.of(traceparent), traceHeaders);
            assertTrue(spans.stream().anyMatch(span -> span.getParentSpanId().equals(parent.getSpanContext().getSpanId())
                    && span.getTraceId().equals(parent.getSpanContext().getTraceId())));
            assertFalse(payloads.isEmpty(), "Existing OTLP exporter must reach the local collector");
            String exported = payloads.toString() + spans.toString();
            assertFalse(exported.contains("calling-sensitive-value"));
            assertFalse(exported.contains("provider-sensitive-value"));
        } finally { server.stop(0); }
    }
}
