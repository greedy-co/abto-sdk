package app.abto.calling;

/** Immutable request identity. Pass the same instance across asynchronous boundaries. */
public record AbtoContext(String featureId, String deviceId, String traceparent, String tracestate) {
    public AbtoContext {
        validate(featureId);
        validate(deviceId);
        validate(traceparent);
        validate(tracestate);
    }

    public AbtoContext(String featureId) { this(featureId, null, null, null); }
    public AbtoContext(String featureId, String deviceId) { this(featureId, deviceId, null, null); }

    private static void validate(String value) {
        if (value != null && (value.indexOf('\r') >= 0 || value.indexOf('\n') >= 0 || value.indexOf('\0') >= 0)) {
            throw new IllegalArgumentException("[abto] Context contains invalid header characters.");
        }
    }
}
