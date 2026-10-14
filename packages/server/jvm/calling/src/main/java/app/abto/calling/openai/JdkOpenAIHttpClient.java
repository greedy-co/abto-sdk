package app.abto.calling.openai;

import com.openai.core.RequestOptions;
import com.openai.core.http.Headers;
import com.openai.core.http.HttpClient;
import com.openai.core.http.HttpRequest;
import com.openai.core.http.HttpResponse;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpResponse.BodyHandlers;
import java.time.Duration;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

/** Native SDK transport over an explicitly supplied JDK client; no retries or resource ownership. */
final class JdkOpenAIHttpClient implements HttpClient {
    private final java.net.http.HttpClient delegate;
    JdkOpenAIHttpClient(java.net.http.HttpClient delegate) { this.delegate = delegate; }
    public HttpResponse execute(HttpRequest request, RequestOptions options) {
        try { return response(delegate.send(request(request, options), BodyHandlers.ofByteArray())); }
        catch (InterruptedException error) { Thread.currentThread().interrupt(); throw new java.util.concurrent.CancellationException("[abto] HTTP request interrupted."); }
        catch (java.io.IOException error) { throw new com.openai.errors.OpenAIIoException("HTTP request failed", error); }
    }
    public CompletableFuture<HttpResponse> executeAsync(HttpRequest request, RequestOptions options) {
        final CompletableFuture<java.net.http.HttpResponse<byte[]>> source;
        try { source = delegate.sendAsync(request(request, options), BodyHandlers.ofByteArray()); }
        catch (RuntimeException error) { return CompletableFuture.failedFuture(error); }
        var result = new CompletableFuture<HttpResponse>();
        source.whenComplete((value, error) -> {
            if (error == null) result.complete(response(value));
            else {
                Throwable cause = error;
                while (cause instanceof java.util.concurrent.CompletionException && cause.getCause() != null) cause = cause.getCause();
                result.completeExceptionally(cause instanceof java.io.IOException ? new com.openai.errors.OpenAIIoException("HTTP request failed", cause) : cause);
            }
        });
        result.whenComplete((value, error) -> { if (result.isCancelled()) source.cancel(true); });
        return result;
    }
    public HttpResponse execute(HttpRequest request) { return execute(request, RequestOptions.none()); }
    public CompletableFuture<HttpResponse> executeAsync(HttpRequest request) { return executeAsync(request, RequestOptions.none()); }
    public void close() {}

    private java.net.http.HttpRequest request(HttpRequest source, RequestOptions options) {
        validateTimeout(options.getTimeout(), delegate);
        var builder = java.net.http.HttpRequest.newBuilder(URI.create(source.url()));
        source.headers().names().forEach(name -> source.headers().values(name).forEach(value -> builder.header(name, value)));
        byte[] body = new byte[0];
        if (source.body() != null) {
            var output = new ByteArrayOutputStream(); source.body().writeTo(output); body = output.toByteArray();
            if (source.body().contentType() != null && source.headers().values("content-type").isEmpty()) builder.header("content-type", source.body().contentType());
        }
        if (options.getTimeout() != null) {
            Duration timeout = options.getTimeout().request();
            if (!timeout.isZero()) builder.timeout(timeout);
        }
        return builder.method(source.method().toString(), java.net.http.HttpRequest.BodyPublishers.ofByteArray(body)).build();
    }
    static void validateTimeout(com.openai.core.Timeout timeout, java.net.http.HttpClient transport) {
        if (timeout == null) return;
        Duration request = timeout.request();
        for (Duration phase : java.util.List.of(timeout.read(), timeout.write())) {
            if (!phase.isZero() && (request.isZero() || phase.compareTo(request) < 0))
                throw new IllegalArgumentException("[abto] JDK transport supports total request timeout; separate shorter read/write timeouts are unsupported.");
        }
        if (!timeout.connect().equals(Duration.ofMinutes(1))
                && !timeout.connect().equals(transport.connectTimeout().orElse(Duration.ZERO)))
            throw new IllegalArgumentException("[abto] Configure connect timeout on the explicitly supplied JDK transport.");
    }
    private static HttpResponse response(java.net.http.HttpResponse<byte[]> response) {
        var headers = Headers.builder(); response.headers().map().forEach(headers::put);
        Headers values = headers.build();
        return new HttpResponse() {
            private final InputStream body = new ByteArrayInputStream(response.body());
            public int statusCode() { return response.statusCode(); }
            public Headers headers() { return values; }
            public Optional<String> requestId() { return response.headers().firstValue("x-request-id"); }
            public InputStream body() { return body; }
            public void close() { try { body.close(); } catch (java.io.IOException error) { throw new java.io.UncheckedIOException(error); } }
        };
    }
}
