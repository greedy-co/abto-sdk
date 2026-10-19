package app.abto.calling.langchain4j;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoFallback;
import com.sun.net.httpserver.HttpServer;
import dev.langchain4j.model.chat.listener.ChatModelListener;
import dev.langchain4j.model.chat.listener.ChatModelRequestContext;
import dev.langchain4j.model.chat.listener.ChatModelResponseContext;
import dev.langchain4j.model.openai.OpenAiChatModel;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import org.bsc.langgraph4j.StateGraph;
import org.bsc.langgraph4j.GraphInput;
import org.bsc.langgraph4j.RunnableConfig;
import org.bsc.langgraph4j.state.AgentState;
import org.junit.jupiter.api.Test;
import static org.bsc.langgraph4j.action.AsyncNodeAction.node_async;
import static org.junit.jupiter.api.Assertions.*;
import static app.abto.calling.internal.CallingContract.*;

class AbtoLangChain4jTest {
    @Test void admissionHeadersSurviveUntilFallbackAndListenersRemainInstalled() throws Exception {
        try (var server = new Server(true); var abto = AbtoLangChain4j.create(server.config(true))) {
            var requests = new AtomicInteger(); var responses = new AtomicInteger();
            var listener = new ChatModelListener() {
                public void onRequest(ChatModelRequestContext context) { requests.incrementAndGet(); }
                public void onResponse(ChatModelResponseContext context) { responses.incrementAndGet(); }
            };
            var builder = OpenAiChatModel.builder().modelName("customer-model").temperature(0.2).listeners(listener)
                    .customHeaders(Map.of("traceparent", "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01", "Cookie", "private-cookie"));
            abto.forContext(AbtoContext.builder("feature").deviceId("device").build()).openAiOptions().accept(builder);
            assertEquals("hello", builder.build().chat("hi"));
            assertEquals(1, requests.get()); assertEquals(1, responses.get());
            assertEquals(List.of("/gateway/v1/chat/completions", "/direct/v1/chat/completions"), server.paths);
            assertEquals(server.bodies.get(0), server.bodies.get(1));
            assertTrue(server.bodies.get(0).contains("customer-model"));
            assertEquals(List.of("Bearer calling-key"), server.headers.get(0).get("Authorization"));
            assertEquals(List.of("Bearer provider-key"), server.headers.get(1).get("Authorization"));
            assertNull(server.headers.get(1).get("Cookie"));
            assertNull(server.headers.get(1).get(HEADER_FEATURE_ID));
            assertEquals(server.headers.get(0).get("Traceparent"), server.headers.get(1).get("Traceparent"));
        }
    }

    @Test void graphNodesCarryExplicitContextWithoutChangingStateExecution() throws Exception {
        try (var server = new Server(false); var abto = AbtoLangChain4j.create(server.config(false))) {
            var graph = new StateGraph<AgentState>(AgentState::new)
                    .addNode("chat", node_async(state -> {
                        String feature = state.<String>value("feature").orElseThrow();
                        var builder = OpenAiChatModel.builder().modelName("graph-model");
                        abto.forContext(AbtoContext.of(feature)).openAiOptions().accept(builder);
                        return Map.of("answer", builder.build().chat(state.<String>value("input").orElseThrow()));
                    }))
                    .addEdge(StateGraph.START, "chat").addEdge("chat", StateGraph.END).compile();
            var first = CompletableFuture.supplyAsync(() -> graph.invoke(GraphInput.args(Map.of("feature", "first", "input", "hi")), RunnableConfig.empty()).orElseThrow());
            var second = CompletableFuture.supplyAsync(() -> graph.invoke(GraphInput.args(Map.of("feature", "second", "input", "hello")), RunnableConfig.empty()).orElseThrow());
            assertEquals("hello", first.join().value("answer").orElseThrow());
            assertEquals("hello", second.join().value("answer").orElseThrow());
            assertEquals(Set.of("first", "second"), Set.copyOf(server.headers.stream().map(h -> h.getFirst(HEADER_FEATURE_ID)).toList()));
        }
    }

    static final class Server implements AutoCloseable {
        final HttpServer server;
        final String base;
        final CopyOnWriteArrayList<String> paths = new CopyOnWriteArrayList<>();
        final CopyOnWriteArrayList<String> bodies = new CopyOnWriteArrayList<>();
        final CopyOnWriteArrayList<com.sun.net.httpserver.Headers> headers = new CopyOnWriteArrayList<>();
        Server(boolean reject) throws Exception {
            server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
            base = "http://127.0.0.1:" + server.getAddress().getPort();
            server.createContext("/", exchange -> {
                paths.add(exchange.getRequestURI().getPath()); headers.add(exchange.getRequestHeaders());
                bodies.add(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
                boolean admission = reject && exchange.getRequestURI().getPath().startsWith("/gateway/");
                exchange.getResponseHeaders().add(HEADER_REQUEST_ID, "request");
                if (admission) exchange.getResponseHeaders().add(HEADER_ERROR_SOURCE, ERROR_SOURCE_GATEWAY);
                byte[] response = (admission ? "{\"error\":{\"message\":\"unavailable\"}}" : "{\"id\":\"chat-test\",\"object\":\"chat.completion\",\"created\":1,\"model\":\"selected\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"hello\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":1,\"completion_tokens\":1,\"total_tokens\":2}}").getBytes(StandardCharsets.UTF_8);
                exchange.getResponseHeaders().add("Content-Type", "application/json");
                exchange.sendResponseHeaders(admission ? 503 : 200, response.length);
                try (var out = exchange.getResponseBody()) { out.write(response); }
            });
            server.start();
        }
        AbtoConfig config(boolean fallback) {
            return AbtoConfig.builder().environment(k -> null).apiKey("calling-key").providerKey("openai", "provider-key").gatewayBaseUrl(base + "/gateway/v1")
                    .fallback(fallback ? AbtoFallback.builder().baseUrl(base + "/direct/v1").build() : null).build();
        }
        public void close() { server.stop(0); }
    }
}
