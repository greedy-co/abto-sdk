import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'config.dart';

/// Batch transport that queues events and flushes on `batchSize` or a timer.
/// Never throws, so telemetry failures cannot block the host app, matching the Browser SDK contract.
class AbtoTransport {
  AbtoTransport(this._config);

  static const _maxBuffer = 1000;
  static const _maxAttempts = 3;
  static const _maxEventAge = Duration(minutes: 5);
  static const _maxResponseBytes = 64 * 1024;

  final AbtoConfig _config;
  final _buffer = <_QueuedEvent>[];
  final _random = Random.secure();
  Timer? _timer;
  Future<void> _inFlight = Future.value();

  void enqueue(Map<String, Object?> event) {
    _buffer.add(_QueuedEvent(event));
    if (_buffer.length >= _config.batchSize) {
      unawaited(flush());
    } else {
      _scheduleFlush(_config.flushInterval);
    }
  }

  Future<void> flush() {
    // Serialize flushes to preserve delivery order.
    _inFlight = _inFlight.then((_) => _drainAndSend());
    return _inFlight;
  }

  Future<void> _drainAndSend() async {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;
    final count =
        _buffer.length < _config.batchSize ? _buffer.length : _config.batchSize;
    final batch = List<_QueuedEvent>.from(_buffer.getRange(0, count));
    _buffer.removeRange(0, count);
    for (final queued in batch) {
      queued.attempts += 1;
    }
    final events = batch.map((queued) => queued.event).toList();

    var retryBatch = <_QueuedEvent>[];
    try {
      final client = HttpClient();
      try {
        final request = await client.postUrl(_config.endpoint);
        request.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
        request.headers.set('authorization', 'Bearer ${_config.projectKey}');
        // `write()` defaults to Latin-1, which corrupts non-ASCII payloads; send UTF-8 bytes directly.
        request.add(utf8.encode(jsonEncode({'batch': events})));
        final response = await request.close();
        final responseBody = await _readBoundedResponse(response);
        if (response.statusCode < 400) {
          final retryEvents = _eventsToRetry(events, responseBody) ?? events;
          retryBatch = batch
              .where((queued) => retryEvents.contains(queued.event))
              .toList();
        } else if (_isTransientStatus(response.statusCode)) {
          retryBatch = batch;
        }
      } finally {
        client.close();
      }
    } catch (_) {
      retryBatch = batch;
    }

    final now = DateTime.now();
    retryBatch = retryBatch
        .where((queued) =>
            queued.attempts < _maxAttempts &&
            now.difference(queued.firstQueuedAt) < _maxEventAge)
        .toList();
    if (retryBatch.isNotEmpty) {
      // Cap the buffer so a dead endpoint cannot grow memory without bound.
      _buffer.insertAll(0, retryBatch);
      if (_buffer.length > _maxBuffer) {
        _buffer.removeRange(_maxBuffer, _buffer.length);
      }
      _scheduleFlush(_retryDelay(retryBatch));
    } else if (_buffer.isNotEmpty) {
      _scheduleFlush(Duration.zero);
    }
  }

  Future<String> _readBoundedResponse(HttpClientResponse response) async {
    final bytes = BytesBuilder(copy: false);
    var size = 0;
    await for (final chunk in response) {
      size += chunk.length;
      if (size > _maxResponseBytes) {
        throw StateError(
            '[abto] collector response exceeded $_maxResponseBytes bytes.');
      }
      bytes.add(chunk);
    }
    return utf8.decode(bytes.takeBytes());
  }

  Duration _retryDelay(List<_QueuedEvent> batch) {
    final attempt =
        batch.fold<int>(1, (largest, queued) => max(largest, queued.attempts));
    final baseMs = max(1, _config.flushInterval.inMilliseconds);
    final exponentialMs = min(60 * 1000, baseMs * (1 << (attempt - 1)));
    return Duration(
        milliseconds:
            exponentialMs + _random.nextInt(max(1, exponentialMs ~/ 2)));
  }

  void _scheduleFlush(Duration delay) {
    _timer ??= Timer(delay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  bool _isTransientStatus(int status) =>
      status == 408 || status == 429 || status >= 500;

  List<Map<String, Object?>>? _eventsToRetry(
      List<Map<String, Object?>> batch, String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;
      final results = decoded['results'];
      if (results is! Map<String, dynamic>) return null;
      return batch.where((event) {
        final eventId = event['event_id'];
        if (eventId is! String) return true;
        final eventResult = results[eventId];
        if (eventResult is! Map<String, dynamic>) return true;
        final result = eventResult['result'];
        return result != 'ok' && result != 'warning' && result != 'drop';
      }).toList();
    } catch (_) {
      return null;
    }
  }
}

class _QueuedEvent {
  _QueuedEvent(this.event) : firstQueuedAt = DateTime.now();

  final Map<String, Object?> event;
  final DateTime firstQueuedAt;
  int attempts = 0;
}
