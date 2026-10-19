package app.abto.calling.springai2;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoFallback;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.OpenAiChatOptions;
import io.micrometer.observation.Observation;
import io.micrometer.observation.ObservationHandler;
import io.micrometer.observation.ObservationRegistry;
import static org.junit.jupiter.api.Assertions.*;
import static app.abto.calling.internal.CallingContract.*;

class AbtoSpringAI2Test {
    @Test void injectsNativeClientsAndKeepsCustomerObservationRegistry() throws Exception {
        var calls = new CopyOnWriteArrayList<String>();
        var bodies = new CopyOnWriteArrayList<String>();
        var observed = new AtomicInteger();
        var registry = ObservationRegistry.create();
        registry.observationConfig().observationHandler(new ObservationHandler<Observation.Context>() {
            public boolean supportsContext(Observation.Context context) { return true; }
            public void onStop(Observation.Context context) { observed.incrementAndGet(); }
        });
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        String base = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/", exchange -> {
            calls.add(exchange.getRequestURI().getPath());
            bodies.add(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            boolean gateway = exchange.getRequestURI().getPath().startsWith("/gateway/");
            assertEquals(gateway ? "Bearer calling-key" : "Bearer provider-key", exchange.getRequestHeaders().getFirst("Authorization"));
            if (gateway) {
                assertEquals("feature", exchange.getRequestHeaders().getFirst(HEADER_FEATURE_ID));
                exchange.getResponseHeaders().add(HEADER_REQUEST_ID, "admission");
                exchange.getResponseHeaders().add(HEADER_ERROR_SOURCE, ERROR_SOURCE_GATEWAY);
            } else assertNull(exchange.getRequestHeaders().getFirst(HEADER_PROVIDER_KEY_PREFIX + "openai"));
            byte[] result = (gateway ? "{\"error\":{\"message\":\"unavailable\"}}" : "{\"id\":\"chat-test\",\"object\":\"chat.completion\",\"created\":1,\"model\":\"selected\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"hello\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":1,\"completion_tokens\":1,\"total_tokens\":2}}").getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.sendResponseHeaders(gateway ? 503 : 200, result.length);
            try (var out = exchange.getResponseBody()) { out.write(result); }
        });
        server.start();
        try {
            var config = AbtoConfig.builder().environment(k -> null).apiKey("calling-key").providerKey("openai", "provider-key")
                    .gatewayBaseUrl(base + "/gateway/v1").fallback(AbtoFallback.builder().baseUrl(base + "/direct/v1").build()).build();
            try (var abto = AbtoSpringAI2.create(config)) {
                var modelBuilder = OpenAiChatModel.builder().options(OpenAiChatOptions.builder().model("customer-model").temperature(0.2).build()).observationRegistry(registry);
                abto.forContext(AbtoContext.of("feature")).chatModelOptions().accept(modelBuilder);
                assertEquals("hello", modelBuilder.build().call("hello"));
            }
            assertTrue(observed.get() > 0);
            assertEquals(java.util.List.of("/gateway/v1/chat/completions", "/direct/v1/chat/completions"), calls);
            assertEquals(bodies.get(0), bodies.get(1));
            assertTrue(bodies.get(0).contains("customer-model"));
        } finally { server.stop(0); }
    }
}
