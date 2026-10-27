package app.abto.calling;

import java.io.IOException;
import java.net.Authenticator;
import java.net.CookieHandler;
import java.net.ProxySelector;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executor;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLParameters;

/** JDK HTTP adapter for non-streaming Chat Completions and Responses with replayable request bodies. */
public final class AbtoHttpClient extends HttpClient {
    private final HttpClient delegate;
    private final AbtoGateway gateway;

    private AbtoHttpClient(HttpClient delegate, AbtoGateway gateway) {
        this.delegate = Objects.requireNonNull(delegate);
        this.gateway = Objects.requireNonNull(gateway);
        if (delegate.followRedirects() != Redirect.NEVER) throw new IllegalArgumentException("[abto] HTTP redirects must be disabled to protect Gateway credentials.");
        if (delegate.cookieHandler().isPresent() || delegate.authenticator().isPresent()) throw new IllegalArgumentException("[abto] The JDK transport must not add cookies or authenticator credentials after dispatch.");
    }
    public static AbtoHttpClient wrap(HttpClient client, AbtoGateway gateway) { return new AbtoHttpClient(client, gateway); }
    public AbtoHttpClient forContext(AbtoContext context) { return new AbtoHttpClient(delegate, gateway.forContext(context)); }

    @Override public <T> HttpResponse<T> send(HttpRequest request, HttpResponse.BodyHandler<T> handler) throws IOException, InterruptedException {
        try {
            return gateway.execute(request.uri(), request.method(), request.headers().map(), dispatch -> delegate.send(request(request, dispatch), handler), response());
        } catch (IOException | InterruptedException error) { throw error; }
        catch (RuntimeException error) { throw error; }
        catch (Exception error) { throw new IOException(error); }
    }
    @Override public <T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest request, HttpResponse.BodyHandler<T> handler) {
        return gateway.executeAsync(request.uri(), request.method(), request.headers().map(), dispatch -> delegate.sendAsync(request(request, dispatch), handler), response());
    }
    @Override public <T> CompletableFuture<HttpResponse<T>> sendAsync(HttpRequest request, HttpResponse.BodyHandler<T> handler, HttpResponse.PushPromiseHandler<T> pushHandler) {
        if (pushHandler != null) return CompletableFuture.failedFuture(new UnsupportedOperationException("[abto] HTTP push is not supported."));
        return sendAsync(request, handler);
    }

    private static HttpRequest request(HttpRequest source, AbtoGateway.Dispatch dispatch) {
        var builder = HttpRequest.newBuilder(dispatch.uri()).expectContinue(source.expectContinue())
                .method(source.method(), source.bodyPublisher().orElse(HttpRequest.BodyPublishers.noBody()));
        source.version().ifPresent(builder::version);
        Duration timeout = source.timeout().orElse(null);
        if (dispatch.timeout() != null && (timeout == null || dispatch.timeout().compareTo(timeout) < 0)) timeout = dispatch.timeout();
        if (timeout != null) builder.timeout(timeout);
        dispatch.headers().forEach((name, values) -> values.forEach(value -> builder.header(name, value)));
        return builder.build();
    }
    private static <T> AbtoGateway.Response<HttpResponse<T>> response() {
        return new AbtoGateway.Response<>() {
            public int status(HttpResponse<T> response) { return response.statusCode(); }
            public Map<String, List<String>> headers(HttpResponse<T> response) { return response.headers().map(); }
            public void discard(HttpResponse<T> response) throws Exception {
                if (response.body() instanceof AutoCloseable body) body.close();
            }
        };
    }

    @Override public Optional<CookieHandler> cookieHandler() { return delegate.cookieHandler(); }
    @Override public Optional<Duration> connectTimeout() { return delegate.connectTimeout(); }
    @Override public Redirect followRedirects() { return delegate.followRedirects(); }
    @Override public Optional<ProxySelector> proxy() { return delegate.proxy(); }
    @Override public SSLContext sslContext() { return delegate.sslContext(); }
    @Override public SSLParameters sslParameters() { return delegate.sslParameters(); }
    @Override public Optional<Authenticator> authenticator() { return delegate.authenticator(); }
    @Override public Version version() { return delegate.version(); }
    @Override public Optional<Executor> executor() { return delegate.executor(); }
    // Explicit no-ops also preserve borrowed ownership on Java 21+.
    public void close() {}
    public void shutdown() {}
    public void shutdownNow() {}
    public boolean awaitTermination(Duration duration) { return true; }
    public boolean isTerminated() { return false; }
}
