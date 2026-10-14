package app.abto.calling.openai;

import app.abto.calling.AbtoConfig;
import app.abto.calling.AbtoCancellation;
import app.abto.calling.AbtoContext;
import app.abto.calling.AbtoGateway;
import com.openai.client.OpenAIClient;
import com.openai.client.OpenAIClientImpl;
import app.abto.calling.AbtoHttpClient;
import com.openai.core.ClientOptions;
import com.openai.core.Sleeper;
import java.net.http.HttpClient;
import java.time.Duration;
import java.util.Objects;
import java.util.concurrent.CompletableFuture;
import java.util.function.Consumer;
import java.util.function.Function;

/** Creates official OpenAI clients or configures existing ones with the same Gateway policy. */
public final class AbtoOpenAI implements AutoCloseable {
    private final AbtoGateway gateway;
    private final Clients clients;
    private final boolean owner;

    private AbtoOpenAI(AbtoGateway gateway, Clients clients, boolean owner) {
        this.gateway = gateway; this.clients = clients; this.owner = owner;
        if (clients.transport != null) AbtoHttpClient.wrap(clients.transport, gateway);
    }
    public static AbtoOpenAI create(AbtoConfig config) { return new AbtoOpenAI(new AbtoGateway(config), new Clients(null, null), true); }
    /** Borrows a redirect-disabled JDK transport, including its proxy, executor and pool. */
    public static AbtoOpenAI create(AbtoConfig config, HttpClient transport) { return new AbtoOpenAI(new AbtoGateway(config), new Clients(null, Objects.requireNonNull(transport)), true); }
    /** Borrows client options and the explicitly supplied transport without taking ownership. */
    public static AbtoOpenAI create(AbtoConfig config, OpenAIClient client, HttpClient transport) {
        return new AbtoOpenAI(new AbtoGateway(config), new Clients(Objects.requireNonNull(client), Objects.requireNonNull(transport)), true);
    }
    public AbtoOpenAI forContext(AbtoContext context) { return new AbtoOpenAI(gateway.forContext(context), clients, false); }
    public AbtoOpenAI withCancellation(AbtoCancellation cancellation) { return new AbtoOpenAI(gateway.withCancellation(cancellation), clients, false); }
    public <T> T withContext(AbtoContext context, Function<AbtoOpenAI, T> callback) { return callback.apply(forContext(context)); }
    public AbtoGateway gateway() { return gateway; }

    /** A borrowed view; close this AbtoOpenAI facade to release a factory-created pool. */
    public OpenAIClient openai() { return clients.get().withOptions(openaiOptions(clients.transport())); }

    /** Apply with withOptions(); explicitly supplying transport avoids unsafe hidden redirects. */
    public Consumer<ClientOptions.Builder> openaiOptions(HttpClient transport) {
        AbtoHttpClient.wrap(transport, gateway);
        return builder -> {
            clients.checkOpen();
            ClientOptions original = builder.build();
            JdkOpenAIHttpClient.validateTimeout(original.timeout(), transport);
            builder.baseUrl(gateway.config().gatewayBaseUrl().toString()).apiKey(AbtoConfig.AUTH_PLACEHOLDER)
                    .httpClient(new GatewayHttpClient(new JdkOpenAIHttpClient(transport), gateway))
                    .streamHandlerExecutor(original.streamHandlerExecutor()::execute)
                    .sleeper(new BorrowedSleeper(original.sleeper()));
        };
    }

    @Override public void close() { if (owner) clients.close(); }

    private static final class Clients {
        private OpenAIClient client;
        private HttpClient transport;
        private final boolean borrowedClient, borrowedTransport;
        private boolean closed;
        Clients(OpenAIClient client, HttpClient transport) {
            this.client = client; this.transport = transport; borrowedClient = client != null; borrowedTransport = transport != null;
        }
        synchronized HttpClient transport() {
            checkOpen();
            if (transport == null) transport = HttpClient.newBuilder().followRedirects(HttpClient.Redirect.NEVER).connectTimeout(Duration.ofMinutes(1)).build();
            return transport;
        }
        synchronized void checkOpen() { if (closed) throw new IllegalStateException("[abto] Client is closed."); }
        synchronized OpenAIClient get() {
            checkOpen();
            if (client == null) client = new OpenAIClientImpl(ClientOptions.builder().apiKey(AbtoConfig.AUTH_PLACEHOLDER).httpClient(new JdkOpenAIHttpClient(transport())).build());
            return client;
        }
        synchronized void close() {
            if (!closed) {
                closed = true;
                try { if (!borrowedClient && client != null) client.close(); }
                finally {
                    // Java 17 releases its JDK pool when unreachable; Java 21+ supports explicit close.
                    if (!borrowedTransport && transport instanceof AutoCloseable closeable) {
                        try { closeable.close(); } catch (Exception error) { throw new IllegalStateException("[abto] Failed to close HTTP transport.", error); }
                    }
                    client = null; transport = null;
                }
            }
        }
    }
    private record BorrowedSleeper(Sleeper delegate) implements Sleeper {
        public void sleep(Duration duration) { delegate.sleep(duration); }
        public CompletableFuture<Void> sleepAsync(Duration duration) { return delegate.sleepAsync(duration); }
        public void close() {}
    }
}
