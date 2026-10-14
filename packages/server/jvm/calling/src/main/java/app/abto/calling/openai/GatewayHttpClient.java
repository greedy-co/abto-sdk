package app.abto.calling.openai;

import app.abto.calling.AbtoGateway;
import com.openai.core.RequestOptions;
import com.openai.core.Timeout;
import com.openai.core.http.Headers;
import com.openai.core.http.HttpClient;
import com.openai.core.http.HttpRequest;
import com.openai.core.http.HttpResponse;
import java.net.URI;
import java.time.Duration;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

final class GatewayHttpClient implements HttpClient {
    private final HttpClient delegate;
    private final AbtoGateway gateway;
    GatewayHttpClient(HttpClient delegate, AbtoGateway gateway) { this.delegate = delegate; this.gateway = gateway; }

    @Override public HttpResponse execute(HttpRequest request, RequestOptions options) {
        try {
            return gateway.execute(URI.create(request.url()), request.method().toString(), headers(request.headers()),
                    dispatch -> delegate.execute(request(request, dispatch), options(options, dispatch)), RESPONSE);
        } catch (RuntimeException error) { throw error; }
        catch (Exception error) { throw new IllegalStateException(error); }
    }
    @Override public CompletableFuture<HttpResponse> executeAsync(HttpRequest request, RequestOptions options) {
        return gateway.executeAsync(URI.create(request.url()), request.method().toString(), headers(request.headers()),
                dispatch -> delegate.executeAsync(request(request, dispatch), options(options, dispatch)), RESPONSE);
    }
    @Override public HttpResponse execute(HttpRequest request) { return execute(request, RequestOptions.none()); }
    @Override public CompletableFuture<HttpResponse> executeAsync(HttpRequest request) { return executeAsync(request, RequestOptions.none()); }
    @Override public void close() {}

    private static HttpRequest request(HttpRequest source, AbtoGateway.Dispatch dispatch) {
        var headers = Headers.builder();
        dispatch.headers().forEach(headers::put);
        // url() already contains the encoded query; avoid appending it a second time.
        return source.toBuilder().baseUrl(dispatch.uri().toString()).pathSegments(List.of()).queryParams(Map.of()).headers(headers.build()).build();
    }
    private static RequestOptions options(RequestOptions source, AbtoGateway.Dispatch dispatch) {
        if (dispatch.timeout() == null) return source;
        Timeout current = source.getTimeout();
        if (current == null) current = Timeout.builder().build();
        Duration timeout = current.request();
        if (timeout.isZero() || dispatch.timeout().compareTo(timeout) < 0) timeout = dispatch.timeout();
        var builder = RequestOptions.builder().timeout(current.toBuilder().request(timeout).build());
        if (source.getResponseValidation() != null) builder.responseValidation(source.getResponseValidation());
        return builder.build();
    }
    private static Map<String, List<String>> headers(Headers headers) {
        var values = new LinkedHashMap<String, List<String>>();
        headers.names().forEach(name -> values.put(name, headers.values(name)));
        return values;
    }
    private static final AbtoGateway.Response<HttpResponse> RESPONSE = new AbtoGateway.Response<>() {
        public int status(HttpResponse response) { return response.statusCode(); }
        public Map<String, List<String>> headers(HttpResponse response) { return GatewayHttpClient.headers(response.headers()); }
        public void discard(HttpResponse response) { response.close(); }
    };
}
