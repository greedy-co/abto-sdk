package app.abto.calling;

import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.CopyOnWriteArrayList;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static app.abto.calling.internal.CallingContract.*;

class AbtoHttpClientTest {
    @Test void realHttpSyncAsyncAndFallbackPreserveBodyAndRawHeaders() throws Exception {
        var calls = new CopyOnWriteArrayList<String>();
        var server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        String base = "http://127.0.0.1:" + server.getAddress().getPort();
        server.createContext("/", exchange -> {
            String path = exchange.getRequestURI().getPath();
            calls.add(path + ":" + exchange.getRequestHeaders().getFirst("Authorization") + ":" + exchange.getRequestHeaders().getFirst(HEADER_FEATURE_ID));
            byte[] body = exchange.getRequestBody().readAllBytes();
            exchange.getResponseHeaders().add("x-preserved", "value");
            exchange.sendResponseHeaders(path.startsWith("/gateway/") ? 503 : 200, body.length);
            try (var out = exchange.getResponseBody()) { out.write(body); }
        });
        server.start();
        try {
            var config = AbtoConfig.builder().environment(k -> null).apiKey("calling").providerKey("openai", "provider")
                    .gatewayBaseUrl(base + "/gateway/v1").fallback(AbtoFallback.builder().baseUrl(base + "/direct/v1").build()).build();
            var borrowed = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(7)).build();
            var client = AbtoHttpClient.wrap(borrowed, new AbtoGateway(config).forContext(new AbtoContext("feature")));
            assertEquals(borrowed.connectTimeout(), client.connectTimeout());
            String json = "{\"messages\":[{\"role\":\"user\",\"content\":\"안녕\"}],\"model\":\"test\"}";
            var request = HttpRequest.newBuilder(URI.create(base + "/gateway/v1/chat/completions")).POST(HttpRequest.BodyPublishers.ofString(json)).build();
            var response = client.send(request, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
            assertEquals(200, response.statusCode()); assertEquals(json, response.body());
            assertEquals("value", response.headers().firstValue("x-preserved").orElseThrow());
            assertEquals(json, client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).join().body());
            client.close();
            assertEquals(200, borrowed.send(HttpRequest.newBuilder(URI.create(base + "/direct/v1/chat/completions")).POST(HttpRequest.BodyPublishers.ofString(json)).build(), HttpResponse.BodyHandlers.discarding()).statusCode());
            assertEquals("/gateway/v1/chat/completions:Bearer calling:feature", calls.get(0));
            assertEquals("/direct/v1/chat/completions:Bearer provider:null", calls.get(1));
            assertEquals("/direct/v1/chat/completions:Bearer provider:null", calls.get(2));
        } finally { server.stop(0); }
    }

    @Test void redirectsAreRejectedBeforeCredentialDispatch() {
        assertThrows(IllegalArgumentException.class, () -> AbtoHttpClient.wrap(HttpClient.newBuilder().followRedirects(HttpClient.Redirect.ALWAYS).build(), new AbtoGateway(AbtoGatewayTest.enabled())));
    }
}
