package example;

import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoGateway;
import app.abto.calling.AbtoHttpClient;
import app.abto.calling.openai.AbtoOpenAI;
import com.openai.client.okhttp.OpenAIOkHttpClient;
import com.openai.models.chat.completions.ChatCompletionCreateParams;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

public final class JavaExample {
    public static void main(String[] args) throws Exception {
        try (var example = ExampleGateway.start(args)) {
            var config = example.config();
            var transport = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NEVER).connectTimeout(Duration.ofSeconds(5)).build();
            try {
            try (var abto = AbtoOpenAI.create(config, transport)) {
                var params = ChatCompletionCreateParams.builder().model("gpt-4o-mini").addUserMessage("Say hello.").build();
                var factory = abto.forContext(AbtoContext.builder("support.reply").deviceId("example-device").build()).openai();
                factory.chat().completions().create(params);

                // Apply ABTO to the customer's options, explicitly sharing its safe JDK transport.
                var existing = OpenAIOkHttpClient.builder().apiKey("transport-placeholder").followRedirects(false).maxRetries(1).timeout(Duration.ofSeconds(20)).build();
                try {
                    var configured = existing.withOptions(abto.forContext(AbtoContext.of("support.config")).openaiOptions(transport));
                    configured.chat().completions().create(params);
                } finally { existing.close(); }
            }

            // The core module also works without an OpenAI client.
            var http = AbtoHttpClient.wrap(transport, new AbtoGateway(config).forContext(AbtoContext.of("support.http")));
            var request = HttpRequest.newBuilder(config.gatewayBaseUrl().resolve("chat/completions"))
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString("{\"model\":\"gpt-4o-mini\",\"messages\":[{\"role\":\"user\",\"content\":\"Say hello.\"}]}"))
                    .build();
            var response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) throw new IllegalStateException("HTTP call failed: " + response.statusCode());
            example.verify("support.reply", "support.config", "support.http");
            System.out.println("Java factory, config and HTTP examples passed.");
            } finally { if (transport instanceof AutoCloseable closeable) closeable.close(); }
        }
    }
}
