package app.abto.calling;

import java.util.Objects;

/**
 * Immutable request identity. Pass the same instance across asynchronous boundaries.
 * Create it with {@link #of(String)} or {@link #builder(String)}.
 */
public final class AbtoContext {
    private final String featureId;
    private final String nodeId;
    private final String deviceId;
    private final String traceparent;
    private final String tracestate;

    private AbtoContext(Builder builder) {
        featureId = validate(builder.featureId);
        if (featureId == null || featureId.isBlank()) throw new IllegalArgumentException("[abto] featureId is required.");
        nodeId = validate(builder.nodeId);
        if (nodeId != null && nodeId.isBlank()) throw new IllegalArgumentException("[abto] nodeId must not be blank.");
        deviceId = validate(builder.deviceId);
        traceparent = validate(builder.traceparent);
        tracestate = validate(builder.tracestate);
    }

    public static AbtoContext of(String featureId) { return builder(featureId).build(); }

    public static Builder builder(String featureId) { return new Builder(featureId); }

    public String featureId() { return featureId; }
    /** Call site inside the feature, sent as {@code x-abto-node-id}. Null means the Gateway uses the feature ID. */
    public String nodeId() { return nodeId; }
    public String deviceId() { return deviceId; }
    public String traceparent() { return traceparent; }
    public String tracestate() { return tracestate; }

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
        private String traceparent;
        private String tracestate;

        private Builder(String featureId) { this.featureId = featureId; }

        public Builder nodeId(String value) { nodeId = value; return this; }
        public Builder deviceId(String value) { deviceId = value; return this; }
        /** Used only when the outgoing request carries no traceparent of its own. */
        public Builder traceparent(String value) { traceparent = value; return this; }
        public Builder tracestate(String value) { tracestate = value; return this; }

        public AbtoContext build() { return new AbtoContext(this); }
    }
}
