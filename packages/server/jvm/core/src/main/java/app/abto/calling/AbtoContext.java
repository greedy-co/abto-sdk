package app.abto.calling;

import java.security.SecureRandom;
import java.util.HexFormat;
import java.util.Objects;

/**
 * Immutable request identity. Pass the same instance across asynchronous boundaries.
 * Create it with {@link #of(String)} or {@link #builder(String)}.
 */
public final class AbtoContext {
    private static final SecureRandom RANDOM = new SecureRandom();

    private final String featureId;
    private final String nodeId;
    private final String deviceId;
    private final String traceId;
    private final String traceparent;
    private final String tracestate;

    private AbtoContext(Builder builder) {
        featureId = validate(builder.featureId);
        if (featureId == null || featureId.isBlank()) throw new IllegalArgumentException("[abto] featureId is required.");
        nodeId = validate(builder.nodeId);
        if (nodeId != null && nodeId.isBlank()) throw new IllegalArgumentException("[abto] nodeId must not be blank.");
        deviceId = validate(builder.deviceId);
        // One context is one run. Without a value to continue, it opens a new run.
        traceId = builder.traceId == null || builder.traceId.isEmpty() ? createTraceId() : validate(builder.traceId);
        traceparent = validate(builder.traceparent);
        tracestate = validate(builder.tracestate);
    }

    public static AbtoContext of(String featureId) { return builder(featureId).build(); }

    public static Builder builder(String featureId) { return new Builder(featureId); }

    /** New trace id: a UUIDv7 as 32 lowercase hex characters, the same form every ABTO SDK generates. */
    public static String createTraceId() {
        // The Java 17 standard library has no UUIDv7 generator, so this fills the RFC 9562 bit layout itself.
        byte[] bytes = new byte[16];
        RANDOM.nextBytes(bytes);
        long millis = System.currentTimeMillis();
        for (int i = 0; i < 6; i++) bytes[i] = (byte) (millis >>> (40 - 8 * i));
        bytes[6] = (byte) ((bytes[6] & 0x0f) | 0x70);
        bytes[8] = (byte) ((bytes[8] & 0x3f) | 0x80);
        return HexFormat.of().formatHex(bytes);
    }

    /** The same run at another call site: every field, the trace id included, stays and only the node changes. */
    public AbtoContext withNodeId(String value) {
        return builder(featureId).nodeId(value).deviceId(deviceId).traceId(traceId).traceparent(traceparent).tracestate(tracestate).build();
    }

    public String featureId() { return featureId; }
    /** Call site inside the feature, sent as {@code x-abto-node-id}. Null means the Gateway uses the feature ID. */
    public String nodeId() { return nodeId; }
    public String deviceId() { return deviceId; }
    /** One agent or workflow run, sent as {@code x-abto-trace-id}. Created when the builder was given none. */
    public String traceId() { return traceId; }
    public String traceparent() { return traceparent; }
    public String tracestate() { return tracestate; }

    // The trace id rides along with the identity rather than being part of it, so two contexts for the same call site stay equal across runs.
    @Override public boolean equals(Object other) {
        return other instanceof AbtoContext c && featureId.equals(c.featureId) && Objects.equals(nodeId, c.nodeId)
            && Objects.equals(deviceId, c.deviceId) && Objects.equals(traceparent, c.traceparent) && Objects.equals(tracestate, c.tracestate);
    }

    @Override public int hashCode() { return Objects.hash(featureId, nodeId, deviceId, traceparent, tracestate); }

    @Override public String toString() { return "AbtoContext[featureId=" + featureId + ", nodeId=" + nodeId + ", deviceId=" + deviceId + "]"; }

    private static String validate(String value) {
        if (value != null && (value.indexOf('\r') >= 0 || value.indexOf('\n') >= 0 || value.indexOf('\0') >= 0)) {
            throw new IllegalArgumentException("[abto] Context contains invalid header characters.");
        }
        return value;
    }

    public static final class Builder {
        private final String featureId;
        private String nodeId;
        private String deviceId;
        private String traceId;
        private String traceparent;
        private String tracestate;

        private Builder(String featureId) { this.featureId = featureId; }

        public Builder nodeId(String value) { nodeId = value; return this; }
        public Builder deviceId(String value) { deviceId = value; return this; }
        public Builder traceId(String value) { traceId = value; return this; }
        /** Used only when the outgoing request carries no traceparent of its own. */
        public Builder traceparent(String value) { traceparent = value; return this; }
        public Builder tracestate(String value) { tracestate = value; return this; }

        public AbtoContext build() { return new AbtoContext(this); }
    }
}
