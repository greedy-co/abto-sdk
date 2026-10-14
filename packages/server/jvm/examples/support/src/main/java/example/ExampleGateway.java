package example;

import app.abto.calling.AbtoConfig;
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import static app.abto.calling.internal.CallingContract.*;

/** A local-only fixture selected by --self-test; normal examples read server-side environment variables. */
public final class ExampleGateway implements AutoCloseable {
    private final HttpServer server;
    private final CopyOnWriteArrayList<String> features = new CopyOnWriteArrayList<>();
    private ExampleGateway(HttpServer server) { this.server = server; }
    public static ExampleGateway start(String[] args) throws Exception {
        if (!List.of(args).contains("--self-test")) return new ExampleGateway(null);
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        var fixture = new ExampleGateway(server);
        server.createContext("/v1/chat/completions", exchange -> {
            exchange.getRequestBody().readAllBytes();
            fixture.features.add(exchange.getRequestHeaders().getFirst(HEADER_FEATURE_ID));
            byte[] body = "{\"id\":\"chat-example\",\"object\":\"chat.completion\",\"created\":1,\"model\":\"example-model\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"hello\"},\"finish_reason\":\"stop\"}],\"usage\":{\"prompt_tokens\":1,\"completion_tokens\":1,\"total_tokens\":2}}".getBytes(StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json");
            exchange.getResponseHeaders().add(HEADER_REQUEST_ID, "example-request");
            exchange.sendResponseHeaders(200, body.length);
            try (var output = exchange.getResponseBody()) { output.write(body); }
        });
        server.start(); return fixture;
    }
    public AbtoConfig config() {
        if (server == null) return AbtoConfig.builder().build();
        return AbtoConfig.builder().environment(key -> null).apiKey("example-calling-key").providerKey("openai", "example-provider-key")
                .gatewayBaseUrl("http://127.0.0.1:" + server.getAddress().getPort() + "/v1").build();
    }
    public void verify(String... expected) {
        if (server != null && !features.equals(List.of(expected))) throw new AssertionError("Unexpected request contexts: " + features);
    }
    public void close() { if (server != null) server.stop(0); }
}
