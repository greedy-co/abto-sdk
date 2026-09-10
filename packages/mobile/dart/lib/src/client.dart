import 'config.dart';
import 'contract.generated.dart';
import 'context.dart';
import 'transport.dart';

// trace_id rides as a first-class wire field, so it is not copied into the bag.
const _envelopeContextKeys = <String, String>{
  'feature_id': r'$feature_id',
  'task_type': r'$task_type',
  'surface': r'$surface',
  'request_id': r'$request_id',
  'response_id': r'$response_id',
};

num? abtoMetricValue(num? value) {
  if (value == null ||
      !value.isFinite ||
      value.abs() >= abtoMetricAbsoluteLimit) {
    return null;
  }
  final parts = value.abs().toString().toLowerCase().split('e');
  final fractionDigits = parts.first
          .split('.')
          .elementAtOrNull(1)
          ?.replaceFirst(RegExp(r'0+$'), '')
          .length ??
      0;
  final exponent = parts.length == 1 ? 0 : int.tryParse(parts[1]) ?? 0;
  return fractionDigits - exponent <= abtoMetricMaxFractionDigits
      ? value
      : null;
}

String? abtoScaleValue(String? value) => value != null &&
        !value.contains('\u0000') &&
        value.length <= abtoScaleMaxLength
    ? value
    : null;

// Mirrors the shallow JsonValue contract without a serialization dependency.
bool abtoValidProperties(Map<String, Object?> properties) {
  bool scalar(Object? v) =>
      v == null ||
      v is bool ||
      (v is String && !v.contains('\u0000')) ||
      (v is num && v.isFinite);
  bool value(Object? v) =>
      scalar(v) ||
      (v is List && v.every(scalar)) ||
      (v is Map &&
          v.entries.every((e) =>
              e.key is String &&
              !(e.key as String).contains('\u0000') &&
              scalar(e.value)));
  return properties.entries.every((e) =>
      !e.key.startsWith(r'$') &&
      !e.key.contains('\u0000') &&
      !abtoCustomMetricFields.contains(e.key) &&
      value(e.value));
}

String? abtoEventNameIssue(String event) {
  if (event.trim().isEmpty) return abtoErrEventNameBlank;
  if (event.contains('\u0000')) return abtoErrEventNameNul;
  if (event.startsWith(r'$')) return abtoErrEventNameDollarPrefix;
  if (abtoReservedEventNames.contains(event)) return abtoErrEventNameReserved;
  if (event.codeUnits.length > abtoEventNameMaxLength) {
    return abtoErrEventNameTooLong;
  }
  return null;
}

/// ABTO SDK entry point for Flutter/Dart.
/// Uses the same event contract as the Browser SDK and posts `{"batch": […]}`
/// to the Analytics ingestion contract: event_id, device_id, event_name, occurred_at, and extra_json.
class AbtoClient {
  AbtoClient(this.config, {AbtoKeyValueStore? store})
      : _context = AbtoContext(store ?? AbtoInMemoryStore()),
        _transport = AbtoTransport(config);

  final AbtoConfig config;
  final AbtoContext _context;
  final AbtoTransport _transport;

  /// Attribution axis shared by Analytics and the Gateway's `x-abto-device-id`.
  String get deviceId => _context.anonymousId;

  /// Session identifier for the current SDK client lifecycle.
  String get sessionId => _context.sessionId;

  void identify(String userId, [String? tenantId]) =>
      _context.identify(userId, tenantId);

  void reset() => _context.reset();

  /// Sends optional [value] and [scale] as metric columns and optional [properties] as extra_json.
  void capture(String event,
      {num? value,
      String? scale,
      Map<String, Object?> properties = const {}}) {
    final issue = abtoEventNameIssue(event);
    if (issue != null) {
      print(abtoErrEventDropped.replaceAll('{issue}', issue));
      return;
    }
    if ((value != null && abtoMetricValue(value) == null) ||
        (scale != null && abtoScaleValue(scale) == null) ||
        !abtoValidProperties(properties)) {
      print(abtoErrCustomCaptureInvalid);
      return;
    }
    _captureEvent(event, value: value, scale: scale, properties: properties);
  }

  void _captureSystemEvent(
    String event, {
    required Map<String, Object?> systemProperties,
    Map<String, Object?> envelope = const {},
  }) =>
      _captureEvent(
        event,
        systemProperties: systemProperties,
        envelope: envelope,
      );

  /// Builds and enqueues one event. Names are checked by the public [capture]; the SDK's own
  /// system event names are constants and need no check.
  void _captureEvent(
    String event, {
    Map<String, Object?> properties = const {},
    Map<String, Object?> systemProperties = const {},
    Map<String, Object?> envelope = const {},
    num? value,
    String? scale,
  }) {
    final traceId = envelope['trace_id'];
    final captured = <String, Object?>{
      'event_id': uuidV7(),
      'device_id': _context.anonymousId,
      'session_id': _context.sessionId,
      if (traceId is String) 'trace_id': traceId,
      'event_name': event,
      if (value != null) 'value': value,
      if (scale != null) 'scale': scale,
      'occurred_at': isoTimestamp(),
      // The bag holds only what no first-class wire field carries. device_id, session_id and
      // trace_id ride at the top level, so a copy here would be a duplicate no aggregation reads,
      // stored forever in every event's jsonb. Context with no column of its own stays, because
      // the bag is its only carrier.
      'extra_json': <String, Object?>{
        ...properties,
        ...Map.fromEntries(
          systemProperties.entries.where((entry) => entry.value != null),
        ),
        r'$lib': 'flutter',
        r'$environment': config.environment.wireName,
        r'$schema_version': abtoSchemaVersion,
        if (_context.userId != null) r'$user_id': _context.userId,
        if (_context.tenantId != null) r'$tenant_id': _context.tenantId,
        for (final entry in envelope.entries)
          if (entry.value is String && _envelopeContextKeys[entry.key] != null)
            _envelopeContextKeys[entry.key]!: entry.value,
      },
    };
    if (config.debug) {
      // ignore: avoid_print — intentional diagnostic output in debug mode.
      print('[abto] $event $captured');
    }
    _transport.enqueue(captured);
  }

  AbtoLlmTrace startLlmTrace(
          {required String featureId, String? taskType, String? surface}) =>
      AbtoLlmTrace._(this, featureId, taskType, surface);

  Future<void> flush() => _transport.flush();
}

/// Lifecycle of one LLM call, joining prior behavior by trace_id and Gateway cost and latency by request_id.
class AbtoLlmTrace {
  AbtoLlmTrace._(this._client, this.featureId, this._taskType, this._surface)
      : traceId = uuidV7TraceId();

  final AbtoClient _client;
  final String featureId;
  final String? _taskType;
  final String? _surface;
  final String traceId;
  String? requestId;

  /// Reads x-abto-request-id from Gateway response headers and attaches it to later events.
  String? attachRequestIdFromHeaders(Map<String, Object?> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'x-abto-request-id') {
        final value = entry.value;
        final id = value is List
            ? (value.isEmpty ? null : value.first?.toString())
            : value?.toString();
        if (id != null && id.isNotEmpty) {
          requestId = id;
          return id;
        }
      }
    }
    return null;
  }

  void attach(String requestId) => this.requestId = requestId;

  void submitPrompt({String? prompt, String? language}) {
    _client._captureSystemEvent(
      'llm_prompt_submitted',
      systemProperties: {
        r'$capture_mode': 'metadata_only',
        if (prompt != null) r'$prompt_length_chars': prompt.length,
        if (language != null) r'$language': language,
      },
      envelope: _envelope(),
    );
  }

  void markResponseVisible(
      {required String responseId,
      String? responseText,
      int? timeToVisibleMs}) {
    _client._captureSystemEvent(
      'llm_response_rendered',
      systemProperties: {
        r'$capture_mode': 'metadata_only',
        r'$response_id': responseId,
        if (responseText != null) r'$output_length_chars': responseText.length,
        if (timeToVisibleMs != null) r'$time_to_render_ms': timeToVisibleMs,
      },
      envelope: _envelope({'response_id': responseId}),
    );
  }

  void captureOutcome(String interactionType, {String? responseId}) {
    final canonical = AbtoResponseInteraction.fromWireValue(interactionType);
    if (canonical == null) {
      print(abtoErrInteractionDropped);
      return;
    }
    _client._captureSystemEvent(
      'llm_response_interacted',
      systemProperties: {
        r'$interaction_type': canonical.wireValue,
        if (responseId != null) r'$response_id': responseId,
        if (requestId != null) r'$request_id': requestId,
      },
      envelope: _envelope(
          responseId != null ? {'response_id': responseId} : const {}),
    );
  }

  Map<String, Object?> _envelope([Map<String, Object?> overrides = const {}]) =>
      {
        'feature_id': featureId,
        'trace_id': traceId,
        if (_taskType != null) 'task_type': _taskType,
        if (_surface != null) 'surface': _surface,
        if (requestId != null) 'request_id': requestId,
        ...overrides,
      };
}
