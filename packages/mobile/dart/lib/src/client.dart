import 'config.dart';
import 'contract.generated.dart';
import 'context.dart';
import 'transport.dart';

const _metricAbsoluteLimit = 1e38;
const _metricMaxFractionDigits = 12;
const _maxScaleLength = 16;
const _envelopeContextKeys = <String, String>{
  'trace_id': r'$trace_id',
  'feature_id': r'$feature_id',
  'task_type': r'$task_type',
  'surface': r'$surface',
  'request_id': r'$request_id',
  'response_id': r'$response_id',
};

num? abtoMetricValue(num? value) {
  if (value == null || !value.isFinite || value.abs() >= _metricAbsoluteLimit) {
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
  return fractionDigits - exponent <= _metricMaxFractionDigits ? value : null;
}

String? abtoScaleValue(String? value) =>
    value != null && value.length <= _maxScaleLength ? value : null;

String? abtoEventNameIssue(String event, {bool allowSystemEvent = false}) {
  if (event.trim().isEmpty) return 'must not be blank';
  if (event.contains('\u0000')) return 'must not contain U+0000';
  if (event.startsWith(r'$')) return r'must not start with $';
  if (!allowSystemEvent && abtoReservedEventNames.contains(event)) {
    return 'must not use an ABTO system event name';
  }
  if (event.codeUnits.length > abtoEventNameMaxLength) {
    return 'must be at most $abtoEventNameMaxLength UTF-16 code units';
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

  /// Manual event delivery, the default path for tracking behavior before an LLM call.
  bool capture(
    String event, {
    Map<String, Object?> properties = const {},
    Map<String, Object?> envelope = const {},
    num? value,
    String? scale,
  }) =>
      _captureEvent(
        event,
        properties: properties,
        envelope: envelope,
        value: value,
        scale: scale,
      );

  bool _captureSystemEvent(
    String event, {
    required Map<String, Object?> systemProperties,
    Map<String, Object?> properties = const {},
    Map<String, Object?> envelope = const {},
  }) =>
      _captureEvent(
        event,
        systemProperties: systemProperties,
        properties: properties,
        envelope: envelope,
        allowSystemEvent: true,
      );

  bool _captureEvent(
    String event, {
    Map<String, Object?> properties = const {},
    Map<String, Object?> systemProperties = const {},
    Map<String, Object?> envelope = const {},
    num? value,
    String? scale,
    bool allowSystemEvent = false,
  }) {
    final eventNameIssue = abtoEventNameIssue(
      event,
      allowSystemEvent: allowSystemEvent,
    );
    if (eventNameIssue != null) {
      // ignore: avoid_print — intentionally reports that an invalid event_name was not sent.
      print('[abto] event was dropped: $eventNameIssue.');
      return false;
    }
    final traceId = envelope['trace_id'];
    final captured = <String, Object?>{
      'event_id': uuidV7(),
      'device_id': _context.anonymousId,
      'session_id': _context.sessionId,
      if (traceId is String) 'trace_id': traceId,
      'event_name': event,
      if (abtoMetricValue(value) case final metricValue?) 'value': metricValue,
      if (abtoScaleValue(scale) case final scaleValue?) 'scale': scaleValue,
      'occurred_at': isoTimestamp(),
      'extra_json': <String, Object?>{
        ...Map.fromEntries(
          properties.entries.where(
            (entry) => entry.value != null && !entry.key.startsWith(r'$'),
          ),
        ),
        ...Map.fromEntries(
          systemProperties.entries.where((entry) => entry.value != null),
        ),
        r'$lib': 'flutter',
        r'$environment': config.environment.wireName,
        r'$schema_version': abtoSchemaVersion,
        r'$device_id': _context.anonymousId,
        r'$anonymous_id': _context.anonymousId,
        r'$session_id': _context.sessionId,
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
    return true;
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

  void captureOutcome(String interactionType,
      {String? responseId, Map<String, Object?> extra = const {}}) {
    final canonical = AbtoResponseInteraction.fromWireValue(interactionType);
    if (canonical == null) {
      print(
          '[abto] response interaction was dropped: unsupported canonical type. Use a custom event for other product actions.');
      return;
    }
    _client._captureSystemEvent(
      'llm_response_interacted',
      systemProperties: {
        r'$interaction_type': canonical.wireValue,
        if (responseId != null) r'$response_id': responseId,
        if (requestId != null) r'$request_id': requestId,
      },
      properties: extra,
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
