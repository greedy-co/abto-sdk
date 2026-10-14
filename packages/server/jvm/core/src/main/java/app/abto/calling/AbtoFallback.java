package app.abto.calling;

import java.net.URI;
import java.time.Duration;
import static app.abto.calling.internal.CallingContract.*;

/** Explicit direct destination and timeout replay policy. Omit from config to disable fallback. */
public final class AbtoFallback {
    private final URI baseUrl;
    private final Duration timeout;
    private final boolean onTimeout;

    private AbtoFallback(Builder builder) {
        if (builder.baseUrl == null || builder.baseUrl.isBlank()) throw new IllegalArgumentException(ERR_FALLBACK_BASE_URL_REQUIRED);
        baseUrl = AbtoConfig.httpUrl(builder.baseUrl, ERR_FALLBACK_BASE_URL_INVALID);
        timeout = builder.timeout;
        if (timeout == null || timeout.isZero() || timeout.isNegative()) throw new IllegalArgumentException(ERR_FALLBACK_TIMEOUT_POSITIVE);
        onTimeout = builder.onTimeout;
    }

    public static Builder builder() { return new Builder(); }
    public URI baseUrl() { return baseUrl; }
    public Duration timeout() { return timeout; }
    public boolean onTimeout() { return onTimeout; }

    /** Builds an explicit fallback destination; defaults to no timeout replay. */
    public static final class Builder {
        private String baseUrl;
        private Duration timeout = Duration.ofMillis(DEFAULT_FALLBACK_TIMEOUT_MS);
        private boolean onTimeout;
        public Builder baseUrl(String value) { baseUrl = value; return this; }
        public Builder timeout(Duration value) { timeout = value; return this; }
        public Builder onTimeout(boolean value) { onTimeout = value; return this; }
        public AbtoFallback build() { return new AbtoFallback(this); }
    }
}
