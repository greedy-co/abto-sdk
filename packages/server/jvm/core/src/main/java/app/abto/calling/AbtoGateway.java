package app.abto.calling;

import java.net.ConnectException;
import java.net.NoRouteToHostException;
import java.net.SocketTimeoutException;
import java.net.URI;
import java.net.UnknownHostException;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.Collections;
import java.util.IdentityHashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.CancellationException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeoutException;
import java.util.function.Function;
import java.util.function.LongSupplier;
import javax.net.ssl.SSLHandshakeException;
import static app.abto.calling.internal.CallingContract.*;

/** Shared dispatch policy used by every adapter. It does not retry provider requests. */
public final class AbtoGateway {
    private final AbtoConfig config;
    private final AbtoContext context;
    private final Circuit circuit;
    private final AbtoCancellation cancellation;

    public AbtoGateway(AbtoConfig config) { this(config, null, new Circuit(System::nanoTime)); }
    AbtoGateway(AbtoConfig config, LongSupplier clock) { this(config, null, new Circuit(clock)); }
    private AbtoGateway(AbtoConfig config, AbtoContext context, Circuit circuit) {
        this(config, context, circuit, null);
    }
    private AbtoGateway(AbtoConfig config, AbtoContext context, Circuit circuit, AbtoCancellation cancellation) {
        this.config = Objects.requireNonNull(config); this.context = context; this.circuit = circuit;
        this.cancellation = cancellation;
    }
    public AbtoConfig config() { return config; }
    public AbtoGateway forContext(AbtoContext value) { return new AbtoGateway(config, Objects.requireNonNull(value), circuit, cancellation); }
    public AbtoGateway withCancellation(AbtoCancellation value) { return new AbtoGateway(config, context, circuit, Objects.requireNonNull(value)); }
    public <T> T withContext(AbtoContext value, Function<AbtoGateway, T> callback) { return callback.apply(forContext(value)); }

    /** A transport instruction. The original method and body remain owned by the caller. */
    public static final class Dispatch {
        private final URI uri;
        private final Map<String, List<String>> headers;
        private final Duration timeout;
        private Dispatch(URI uri, Map<String, List<String>> headers, Duration timeout) {
            this.uri = uri; this.headers = Map.copyOf(headers); this.timeout = timeout;
        }
        public URI uri() { return uri; }
        public Map<String, List<String>> headers() { return headers; }
        /** Gateway timeout cap, or null to retain the caller timeout. */
        public Duration timeout() { return timeout; }
        @Override public String toString() { return "AbtoGateway.Dispatch[headers=redacted]"; }
    }

    @FunctionalInterface public interface Sender<T> { T send(Dispatch dispatch) throws Exception; }
    @FunctionalInterface public interface AsyncSender<T> { CompletableFuture<T> send(Dispatch dispatch); }
    public interface Response<T> {
        int status(T response);
        Map<String, List<String>> headers(T response);
        /** Release a rejected Gateway response before sending the direct request. */
        void discard(T response) throws Exception;
    }

    public <T> T execute(URI uri, String method, Map<String, List<String>> headers, Sender<T> sender, Response<T> response) throws Exception {
        Exchange exchange = prepare(uri, method, headers);
        if (exchange.directFirst) return sender.send(exchange.direct);
        try {
            T result;
            try { result = sender.send(exchange.gateway); }
            catch (Exception error) {
                if (exchange.onFailure(error)) return sender.send(exchange.direct);
                throw error;
            }
            if (cancellation != null && cancellation.isCancelled()) { response.discard(result); cancellation.check(); }
            if (exchange.onResponse(response.status(result), response.headers(result))) {
                response.discard(result);
                return sender.send(exchange.direct);
            }
            return result;
        } finally { exchange.release(); }
    }

    public <T> CompletableFuture<T> executeAsync(URI uri, String method, Map<String, List<String>> headers,
                                                AsyncSender<T> sender, Response<T> response) {
        final Exchange exchange;
        try { exchange = prepare(uri, method, headers); }
        catch (Exception error) { return CompletableFuture.failedFuture(error); }
        var result = new CancellableFuture<T>(exchange::release);
        if (cancellation != null) cancellation.track(result);
        result.start(() -> sender.send(exchange.directFirst ? exchange.direct : exchange.gateway), (value, error) -> {
            if (result.isCancelled()) { discardQuietly(value, response); exchange.release(); return; }
            if (exchange.directFirst) { result.finish(value, error); return; }
            try {
                boolean fallback = error == null
                        ? exchange.onResponse(response.status(value), response.headers(value)) : exchange.onFailure(error);
                if (fallback) {
                    if (value != null) response.discard(value);
                    result.start(() -> sender.send(exchange.direct), result::finish);
                } else result.finish(value, error);
            } catch (Exception failure) { result.completeExceptionally(failure); }
            finally { exchange.release(); }
        });
        return result;
    }

    private static <T> void discardQuietly(T value, Response<T> response) {
        if (value != null) try { response.discard(value); } catch (Exception ignored) { /* Cancellation remains authoritative. */ }
    }

    private Exchange prepare(URI uri, String method, Map<String, List<String>> source) {
        if (cancellation != null) cancellation.check();
        URI base = config.gatewayBaseUrl();
        if (!sameOrigin(uri, base) || uri.getRawUserInfo() != null) throw new IllegalArgumentException(ERR_GATEWAY_ORIGIN_REFUSED);
        var headers = new LinkedHashMap<String, List<String>>();
        source.forEach((name, values) -> {
            String key = name.toLowerCase(Locale.ROOT);
            if (!key.equals("authorization") && !key.equals(HEADER_DEVICE_ID) && !key.equals(HEADER_FEATURE_ID) && !key.startsWith(HEADER_PROVIDER_KEY_PREFIX)) headers.put(key, List.copyOf(values));
        });
        var keys = config.resolveProviderKeys();
        keys.forEach((provider, key) -> headers.put(HEADER_PROVIDER_KEY_PREFIX + provider, List.of(key)));
        headers.put("authorization", List.of("Bearer " + config.resolveApiKey()));
        if (context != null) {
            put(headers, HEADER_FEATURE_ID, context.featureId()); put(headers, HEADER_DEVICE_ID, context.deviceId());
            if (!headers.containsKey("traceparent") && context.traceparent() != null) {
                headers.remove("tracestate");
                put(headers, "traceparent", context.traceparent()); put(headers, "tracestate", context.tracestate());
            }
        }
        AbtoFallback fallback = config.fallback();
        boolean eligible = fallback != null && method.equals("POST") && uri.getRawPath().equals(base.getRawPath() + DIRECT_PATH_SUFFIX);
        String directKey = keys.get("openai");
        Dispatch direct = null;
        if (eligible && directKey != null) {
            var directHeaders = new LinkedHashMap<String, List<String>>();
            headers.forEach((name, values) -> { if (DIRECT_HEADER_NAMES.contains(name) || DIRECT_HEADER_PREFIXES.stream().anyMatch(name::startsWith)) directHeaders.put(name, values); });
            directHeaders.put("authorization", List.of("Bearer " + directKey));
            URI directUri = fallback.baseUrl().resolve(DIRECT_PATH_SUFFIX + (uri.getRawQuery() == null ? "" : "?" + uri.getRawQuery()));
            direct = new Dispatch(directUri, directHeaders, null);
        }
        Circuit.Admission admission = direct == null ? new Circuit.Admission(false, 0) : circuit.enter();
        return new Exchange(new Dispatch(uri, headers, direct == null ? null : fallback.timeout()), direct, eligible, admission);
    }

    private static void put(Map<String, List<String>> headers, String key, String value) {
        if (value != null && !value.isBlank()) headers.put(key, List.of(value));
    }
    private static boolean sameOrigin(URI a, URI b) {
        return a.getHost() != null && a.getHost().equalsIgnoreCase(b.getHost()) && a.getScheme().equalsIgnoreCase(b.getScheme()) && port(a) == port(b);
    }
    private static int port(URI uri) { return uri.getPort() != -1 ? uri.getPort() : "https".equalsIgnoreCase(uri.getScheme()) ? 443 : 80; }
    private static String header(Map<String, List<String>> headers, String name) {
        return headers.entrySet().stream().filter(e -> e.getKey().equalsIgnoreCase(name)).flatMap(e -> e.getValue().stream()).findFirst().orElse(null);
    }
    private static boolean safeResponse(int status, Map<String, List<String>> headers) {
        String requestId = header(headers, HEADER_REQUEST_ID), source = header(headers, HEADER_ERROR_SOURCE);
        return requestId == null && SAFE_GATEWAY_STATUSES.contains(status)
                || status == 503 && requestId != null && (source == null || source.equals(ERROR_SOURCE_GATEWAY));
    }
    private static boolean hasCause(Throwable error, Class<?>... types) {
        var seen = Collections.newSetFromMap(new IdentityHashMap<Throwable, Boolean>());
        for (Throwable cause = error; cause != null && seen.add(cause); cause = cause.getCause()) {
            for (Class<?> type : types) if (type.isInstance(cause)) return true;
        }
        return false;
    }

    private final class Exchange {
        final Dispatch gateway, direct;
        final boolean eligible, directFirst;
        final long probe;
        Exchange(Dispatch gateway, Dispatch direct, boolean eligible, Circuit.Admission admission) {
            this.gateway = gateway; this.direct = direct; this.eligible = eligible;
            directFirst = admission.direct(); probe = admission.probe();
        }
        boolean onResponse(int status, Map<String, List<String>> headers) {
            if (cancellation != null) cancellation.check();
            if (!eligible) return false;
            if (safeResponse(status, headers)) { circuit.open(); return direct != null; }
            circuit.close(); return false;
        }
        boolean onFailure(Throwable error) {
            if (cancellation != null && cancellation.isCancelled()) return false;
            if (!eligible || hasCause(error, CancellationException.class, InterruptedException.class)) return false;
            boolean safe = hasCause(error, ConnectException.class, NoRouteToHostException.class, UnknownHostException.class, SSLHandshakeException.class);
            boolean timeout = config.fallback().onTimeout() && hasCause(error, HttpTimeoutException.class, SocketTimeoutException.class, TimeoutException.class);
            if (safe || timeout) { circuit.open(); return direct != null; }
            return false;
        }
        void release() { circuit.release(probe); }
    }

    private static final class Circuit {
        final LongSupplier clock;
        boolean open;
        long openedAt, activeProbe, sequence;
        Circuit(LongSupplier clock) { this.clock = clock; }
        record Admission(boolean direct, long probe) {}
        synchronized Admission enter() {
            if (!open) return new Admission(false, 0);
            if (clock.getAsLong() - openedAt < Duration.ofMillis(CIRCUIT_OPEN_MS).toNanos() || activeProbe != 0) return new Admission(true, 0);
            activeProbe = ++sequence;
            return new Admission(false, activeProbe);
        }
        synchronized void open() { open = true; openedAt = clock.getAsLong(); activeProbe = 0; }
        synchronized void close() { open = false; activeProbe = 0; }
        synchronized void release(long token) { if (token != 0 && activeProbe == token) activeProbe = 0; }
    }

    private static final class CancellableFuture<T> extends CompletableFuture<T> {
        private CompletableFuture<T> active;
        private final Runnable onCancel;
        CancellableFuture(Runnable onCancel) { this.onCancel = onCancel; }
        synchronized void start(java.util.function.Supplier<CompletableFuture<T>> operation, java.util.function.BiConsumer<T, Throwable> completion) {
            if (isCancelled()) return;
            try { active = operation.get(); active.whenComplete(completion); }
            catch (Exception error) { completion.accept(null, error); }
        }
        void finish(T value, Throwable error) { if (error == null) complete(value); else completeExceptionally(error); }
        @Override public synchronized boolean cancel(boolean interrupt) {
            boolean cancelled = super.cancel(interrupt);
            if (cancelled) { onCancel.run(); if (active != null) active.cancel(interrupt); }
            return cancelled;
        }
    }
}
