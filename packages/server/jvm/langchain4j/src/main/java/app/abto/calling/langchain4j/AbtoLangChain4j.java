package app.abto.calling.langchain4j;

import app.abto.calling.AbtoCancellation;
import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoGateway;
import app.abto.calling.AbtoHttpClient;
import dev.langchain4j.http.client.HttpClientBuilder;
import dev.langchain4j.http.client.jdk.JdkHttpClient;
import dev.langchain4j.model.openai.OpenAiChatModel;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.Objects;
import java.util.function.Consumer;

/** Non-streaming LangChain4j and LangGraph4j integration with dispatch policy below HTTP error conversion. */
public final class AbtoLangChain4j implements AutoCloseable {
    private final AbtoGateway gateway;
    private final Pool pool;
    private final boolean owner;

    private AbtoLangChain4j(AbtoGateway gateway, Pool pool, boolean owner) { this.gateway = gateway; this.pool = pool; this.owner = owner; }
    public static AbtoLangChain4j create(AbtoConfig config) { return create(config, HttpClient.newBuilder()); }
    /** Supply JDK proxy, TLS and executor settings before building models. */
    public static AbtoLangChain4j create(AbtoConfig config, HttpClient.Builder transport) {
        return new AbtoLangChain4j(new AbtoGateway(config), new Pool(Objects.requireNonNull(transport)), true);
    }
    public AbtoLangChain4j forContext(AbtoContext context) { return new AbtoLangChain4j(gateway.forContext(context), pool, false); }
    public AbtoLangChain4j withCancellation(AbtoCancellation cancellation) { return new AbtoLangChain4j(gateway.withCancellation(cancellation), pool, false); }

    /** Retains listeners, model parameters and tool settings on the existing model builder. */
    public Consumer<OpenAiChatModel.OpenAiChatModelBuilder> openAiOptions() {
        return builder -> builder.baseUrl(gateway.config().gatewayBaseUrl().toString()).apiKey(AbtoConfig.AUTH_PLACEHOLDER).httpClientBuilder(httpClientBuilder());
    }
    public OpenAiChatModel openAiChatModel() {
        var builder = OpenAiChatModel.builder(); openAiOptions().accept(builder); return builder.build();
    }
    public HttpClientBuilder httpClientBuilder() { return new Builder(); }
    @Override public void close() { if (owner) pool.close(); }

    private final class Builder implements HttpClientBuilder {
        private Duration connectTimeout, readTimeout;
        public Duration connectTimeout() { return connectTimeout; }
        public Builder connectTimeout(Duration timeout) { connectTimeout = timeout; return this; }
        public Duration readTimeout() { return readTimeout; }
        public Builder readTimeout(Duration timeout) { readTimeout = timeout; return this; }
        public JdkHttpClient build() {
            HttpClient transport = AbtoHttpClient.wrap(pool.get(connectTimeout), gateway);
            return JdkHttpClient.builder().httpClientBuilder(new FixedBuilder(transport)).readTimeout(readTimeout).build();
        }
    }
    private static final class Pool {
        private final HttpClient.Builder builder;
        private HttpClient client;
        private Duration connectTimeout;
        private boolean closed;
        Pool(HttpClient.Builder builder) { this.builder = builder; }
        synchronized HttpClient get(Duration timeout) {
            if (closed) throw new IllegalStateException("[abto] Client is closed.");
            if (client == null) {
                if (timeout != null) builder.connectTimeout(timeout);
                client = builder.build(); connectTimeout = timeout;
            } else if (!Objects.equals(connectTimeout, timeout)) {
                throw new IllegalArgumentException("[abto] Models sharing a connection pool must use the same connect timeout. Create another adapter for a different timeout.");
            }
            return client;
        }
        synchronized void close() {
            if (closed) return;
            closed = true;
            if (client instanceof AutoCloseable closeable) {
                try { closeable.close(); } catch (Exception error) { throw new IllegalStateException("[abto] Failed to close HTTP transport.", error); }
            }
            client = null;
        }
    }

    /** The upstream builder accepts only a JDK builder, so adapt the already shared client. */
    private static final class FixedBuilder implements HttpClient.Builder {
        private final HttpClient client;
        FixedBuilder(HttpClient client) { this.client = client; }
        public HttpClient build() { return client; }
        private UnsupportedOperationException frozen() { return new UnsupportedOperationException("Configure the JDK builder before creating the ABTO adapter."); }
        public HttpClient.Builder cookieHandler(java.net.CookieHandler value) { throw frozen(); }
        public HttpClient.Builder connectTimeout(Duration value) { throw frozen(); }
        public HttpClient.Builder sslContext(javax.net.ssl.SSLContext value) { throw frozen(); }
        public HttpClient.Builder sslParameters(javax.net.ssl.SSLParameters value) { throw frozen(); }
        public HttpClient.Builder executor(java.util.concurrent.Executor value) { throw frozen(); }
        public HttpClient.Builder followRedirects(HttpClient.Redirect value) { throw frozen(); }
        public HttpClient.Builder version(HttpClient.Version value) { throw frozen(); }
        public HttpClient.Builder priority(int value) { throw frozen(); }
        public HttpClient.Builder proxy(java.net.ProxySelector value) { throw frozen(); }
        public HttpClient.Builder authenticator(java.net.Authenticator value) { throw frozen(); }
    }
}
