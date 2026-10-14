package app.abto.calling;

import java.net.URI;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.function.Supplier;
import static app.abto.calling.internal.CallingContract.*;

/** Immutable connection settings. Credentials are resolved by the transport, never serialized as client options. */
public final class AbtoConfig {
    public static final String AUTH_PLACEHOLDER = "abto-transport-placeholder";
    private final URI gatewayBaseUrl;
    private final Supplier<String> apiKey;
    private final Map<String, Supplier<String>> providerKeys;
    private final AbtoFallback fallback;

    private AbtoConfig(Builder builder) {
        String url = builder.gatewayBaseUrl == null ? builder.environment.apply(GATEWAY_BASE_URL_ENV) : builder.gatewayBaseUrl;
        if (url == null || url.isBlank()) throw new IllegalArgumentException(ERR_GATEWAY_BASE_URL_REQUIRED);
        gatewayBaseUrl = httpUrl(url, ERR_GATEWAY_BASE_URL_INVALID);
        String environmentKey = builder.environment.apply(API_KEY_ENV);
        apiKey = builder.apiKey != null ? builder.apiKey : () -> environmentKey;
        if (builder.apiKey == null && (environmentKey == null || environmentKey.isBlank())) throw new IllegalArgumentException(ERR_API_KEY_REQUIRED);
        var keys = new LinkedHashMap<>(builder.providerKeys);
        if (!builder.explicitProviders) {
            for (String provider : PROVIDER_IDS) {
                String value = builder.environment.apply(provider.toUpperCase(Locale.ROOT) + "_API_KEY");
                if (value != null && !value.isBlank()) keys.put(provider, () -> value);
            }
        }
        providerKeys = Map.copyOf(keys);
        fallback = builder.fallback;
        if (fallback != null && !providerKeys.containsKey("openai")) throw new IllegalArgumentException(ERR_FALLBACK_OPENAI_KEY_REQUIRED);
    }

    public static Builder builder() { return new Builder(); }
    public URI gatewayBaseUrl() { return gatewayBaseUrl; }
    public AbtoFallback fallback() { return fallback; }

    String resolveApiKey() { return credential(apiKey.get(), ERR_API_KEY_INVALID_CHARACTERS, true); }
    Map<String, String> resolveProviderKeys() {
        var resolved = new LinkedHashMap<String, String>();
        providerKeys.forEach((provider, source) -> {
            String key = credential(source.get(), ERR_PROVIDER_KEY_INVALID_CHARACTERS.replace("{provider}", provider), false);
            if (key != null) resolved.put(provider, key);
        });
        return resolved;
    }

    static String credential(String value, String invalidMessage, boolean required) {
        if (value != null && (value.indexOf('\r') >= 0 || value.indexOf('\n') >= 0 || value.indexOf('\0') >= 0)) throw new IllegalArgumentException(invalidMessage);
        if (value == null || value.isBlank()) {
            if (required) throw new IllegalArgumentException(ERR_API_KEY_REQUIRED);
            return null;
        }
        return value.trim();
    }

    static URI httpUrl(String value, String message) {
        try {
            URI uri = URI.create(value);
            if (!("https".equalsIgnoreCase(uri.getScheme()) || "http".equalsIgnoreCase(uri.getScheme()))
                    || uri.getHost() == null || uri.getPort() > 65535
                    || uri.getRawUserInfo() != null || uri.getRawQuery() != null || uri.getRawFragment() != null) throw new IllegalArgumentException(message);
            return URI.create(uri.toASCIIString().replaceAll("/+$", "") + "/");
        } catch (IllegalArgumentException error) { throw new IllegalArgumentException(message); }
    }

    @Override public String toString() { return "AbtoConfig[credentials=redacted]"; }

    /** Configures credentials or suppliers; supplier failures surface on the request that resolves them. */
    public static final class Builder {
        private String gatewayBaseUrl;
        private Supplier<String> apiKey;
        private final Map<String, Supplier<String>> providerKeys = new LinkedHashMap<>();
        private boolean explicitProviders;
        private AbtoFallback fallback;
        private Function<String, String> environment = System::getenv;

        public Builder gatewayBaseUrl(String value) { gatewayBaseUrl = value; return this; }
        public Builder apiKey(String value) {
            String checked = credential(value, ERR_API_KEY_INVALID_CHARACTERS, true);
            apiKey = () -> checked; return this;
        }
        public Builder apiKey(Supplier<String> value) { apiKey = Objects.requireNonNull(value); return this; }
        public Builder providerKey(String provider, String value) {
            return providerKey(provider, () -> value);
        }
        public Builder providerKey(String provider, Supplier<String> value) {
            if (!PROVIDER_IDS.contains(provider)) throw new IllegalArgumentException("[abto] Unsupported provider: " + provider);
            explicitProviders = true;
            providerKeys.put(provider, Objects.requireNonNull(value)); return this;
        }
        public Builder fallback(AbtoFallback value) { fallback = value; return this; }
        public Builder environment(Function<String, String> value) { environment = Objects.requireNonNull(value); return this; }
        public AbtoConfig build() { return new AbtoConfig(this); }
        @Override public String toString() { return "AbtoConfig.Builder[credentials=redacted]"; }
    }
}
