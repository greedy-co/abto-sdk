package app.abto.calling.springai1;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoGateway;
import app.abto.calling.AbtoHttpClient;
import java.net.URI;
import java.net.http.HttpClient;
import java.util.Objects;
import java.util.function.Consumer;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.ai.openai.api.OpenAiApi;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.web.client.RestClient;
import static app.abto.calling.internal.CallingContract.DIRECT_PATH_SUFFIX;

/** Spring AI 1.1 non-streaming integration. Reuses the customer's RestClient observers and JDK pool. */
public final class AbtoSpringAI1 implements AutoCloseable {
    private final AbtoGateway gateway;
    private final HttpClient transport;
    private final boolean owner;

    private AbtoSpringAI1(AbtoGateway gateway, HttpClient transport, boolean owner) {
        this.gateway = gateway;
        this.transport = Objects.requireNonNull(transport);
        this.owner = owner;
        AbtoHttpClient.wrap(transport, gateway);
    }
    public static AbtoSpringAI1 create(AbtoConfig config) { return new AbtoSpringAI1(new AbtoGateway(config), HttpClient.newBuilder().build(), true); }
    public static AbtoSpringAI1 create(AbtoConfig config, HttpClient transport) { return new AbtoSpringAI1(new AbtoGateway(config), transport, false); }
    public AbtoSpringAI1 forContext(AbtoContext context) { return new AbtoSpringAI1(gateway.forContext(context), transport, false); }

    /** Configure the chat API; keep a separate API/model for embeddings. */
    public Consumer<OpenAiApi.Builder> openAiApiOptions(RestClient.Builder restClient) {
        return builder -> {
            URI base = gateway.config().gatewayBaseUrl();
            builder.baseUrl(base.getScheme() + "://" + base.getRawAuthority()).completionsPath(base.getRawPath() + DIRECT_PATH_SUFFIX)
                    .apiKey(AbtoConfig.AUTH_PLACEHOLDER)
                    .restClientBuilder(restClient.clone().requestFactory(new JdkClientHttpRequestFactory(AbtoHttpClient.wrap(transport, gateway))));
        };
    }
    public OpenAiApi openAiApi() {
        var builder = OpenAiApi.builder(); openAiApiOptions(RestClient.builder()).accept(builder); return builder.build();
    }
    /** Keeps the existing model options, tool manager, retry template and observation registry. */
    public Consumer<OpenAiChatModel.Builder> chatModelOptions(OpenAiApi api) { return builder -> builder.openAiApi(api); }
    public OpenAiChatModel chatModel() { return OpenAiChatModel.builder().openAiApi(openAiApi()).build(); }
    @Override public void close() {
        if (owner && transport instanceof AutoCloseable closeable) {
            try { closeable.close(); } catch (Exception error) { throw new IllegalStateException("[abto] Failed to close HTTP transport.", error); }
        }
    }
}
