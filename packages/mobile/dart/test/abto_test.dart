import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:abto/abto.dart';
import 'package:abto/src/contract.generated.dart';
import 'package:abto/src/transport.dart';
import 'package:test/test.dart';

final uuidV7Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

final _covered = <String>{};

/// 이 test 가 증명하는 공통 시나리오를 기록한다. 목록의 정본은 계약이다.
void covers(String scenario) {
  assert(abtoConformanceScenarios.contains(scenario),
      'unknown scenario: $scenario');
  _covered.add(scenario);
}

void main() {
  tearDownAll(() {
    final missing = abtoConformanceScenarios
        .where((s) =>
            !_covered.contains(s) && !abtoConformanceExemptions.contains(s))
        .toList();
    expect(missing, isEmpty,
        reason:
            'client conformance scenarios not covered by this SDK: $missing');
  });

  test('response interaction runtime validation uses the generated contract',
      () {
    expect(AbtoResponseInteraction.fromWireValue('copied'),
        AbtoResponseInteraction.copied);
    expect(AbtoResponseInteraction.fromWireValue('retried'), isNull);
  });

  group('init config validation', () {
    test('accepts a minimal valid config', () {
      final config = AbtoConfig(projectKey: 'ek_test');
      expect(
          config.endpoint.toString(), 'https://api.abto.app/v1/collect/events');
      expect(config.environment, AbtoEnvironment.production);
      expect(config.debug, isFalse);
    });

    test('development turns debug on', () {
      expect(
          AbtoConfig(projectKey: 'ek', environment: AbtoEnvironment.development)
              .debug,
          isTrue);
    });

    test('rejects an empty projectKey', () {
      covers('config.project_key_required');
      expect(
        () => AbtoConfig(projectKey: '  '),
        throwsA(predicate((e) => e.toString() == abtoErrProjectKeyRequired)),
      );
    });

    test('rejects a malformed endpoint', () {
      covers('config.endpoint_must_be_url');
      expect(
        () => AbtoConfig(projectKey: 'ek', endpoint: 'htp:/broken url'),
        throwsA(predicate(
            (e) => e.toString().startsWith(abtoErrEndpointInvalidPrefix))),
      );
    });

    test('requires HTTPS outside development loopback', () {
      covers('config.endpoint_requires_https');
      expect(
        () => AbtoConfig(
            projectKey: 'ek',
            endpoint: 'http://collector.example/v1/collect/events'),
        throwsA(predicate((e) => e.toString() == abtoErrEndpointHttpsRequired)),
      );
      expect(
        AbtoConfig(
          projectKey: 'ek',
          endpoint: 'http://127.0.0.1:4870/v1/collect/events',
          environment: AbtoEnvironment.development,
        ).endpoint.scheme,
        'http',
      );
    });

    test('rejects batch sizes outside the collector limit', () {
      covers('config.batch_size_range');
      expect(
        () => AbtoConfig(projectKey: 'ek', batchSize: 0),
        throwsA(predicate((e) => e.toString() == abtoErrBatchSizeRange)),
      );
      expect(
        () => AbtoConfig(projectKey: 'ek', batchSize: 101),
        throwsA(predicate((e) => e.toString() == abtoErrBatchSizeRange)),
      );
    });
  });

  group('context identity', () {
    test('anonymous_id persists across clients, session_id rotates', () {
      covers('identity.anonymous_persists');
      covers('identity.session_rotates');
      covers('identity.uuidv7');
      final store = AbtoInMemoryStore();
      final first = AbtoContext(store);
      final second = AbtoContext(store);
      expect(first.anonymousId, second.anonymousId);
      expect(first.anonymousId, matches(uuidV7Pattern));
      expect(first.sessionId, matches(uuidV7Pattern));
      expect(first.sessionId, isNot(second.sessionId));
    });

    test('identify and reset', () {
      covers('identity.identify_and_reset');
      final context = AbtoContext(AbtoInMemoryStore());
      context.identify('u_1', 't_1');
      expect(context.commonProperties()['user_id'], 'u_1');
      context.identify('u_2');
      expect(context.commonProperties().containsKey('tenant_id'), isFalse);
      final anonBefore = context.anonymousId;
      context.reset();
      expect(context.commonProperties().containsKey('user_id'), isFalse);
      expect(context.anonymousId, isNot(anonBefore));
    });

    test('client exposes the Gateway attribution device id', () {
      final client = AbtoClient(
        AbtoConfig(projectKey: 'ek_test'),
        store: AbtoInMemoryStore(),
      );
      final beforeReset = client.deviceId;
      expect(beforeReset, matches(uuidV7Pattern));
      expect(client.sessionId, matches(uuidV7Pattern));
      client.reset();
      expect(client.deviceId, isNot(beforeReset));
    });

    test('rejects a reserved system event name from public capture', () {
      covers('event.reserved_name_rejected');
      for (final reserved in abtoReservedEventNames) {
        expect(abtoEventNameIssue(reserved), isNotNull, reason: reserved);
      }
    });

    test('omits a metric scale longer than the backend limit', () {
      covers('event.metric_scale_limit');
      final atLimit = 'K' * abtoScaleMaxLength;
      expect(abtoScaleValue(atLimit), atLimit);
      expect(abtoScaleValue('K' * (abtoScaleMaxLength + 1)), isNull);
    });

    test('drops the oldest events past the buffer cap', () async {
      covers('transport.buffer_cap');
      final seen = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(server.forEach((request) async {
        final body = jsonDecode(await utf8.decodeStream(request))
            as Map<String, dynamic>;
        final batch =
            (body['batch'] as List<dynamic>).cast<Map<String, dynamic>>();
        seen.addAll(batch.map((event) => event['event_id'] as String));
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'ok'},
          },
        }));
        await request.response.close();
      }));

      try {
        final transport = AbtoTransport(AbtoConfig(
          projectKey: 'ek_test',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
          flushInterval: const Duration(days: 1),
        ));
        // 상한을 넘겨 적재한 뒤 전부 흘려보내면, 살아남은 것만 수집기에 닿는다.
        final overflow = 10;
        for (var i = 0; i < abtoMaxBufferedEvents + overflow; i++) {
          transport.enqueue(<String, Object?>{'event_id': 'burst-$i'});
        }
        while (seen.length < abtoMaxBufferedEvents) {
          final before = seen.length;
          await transport.flush();
          if (seen.length == before) break;
        }
        expect(seen.length, abtoMaxBufferedEvents);
        // 가장 오래된 것부터 버린다 — 최신 이벤트가 더 유용하다.
        expect(seen.contains('burst-0'), isFalse);
        expect(seen.contains('burst-$overflow'), isTrue);
      } finally {
        await server.close(force: true);
      }
    });

    test('rejects overlong event names with Backend UTF-16 semantics', () {
      covers('event.name_length_limit');
      expect(abtoEventNameIssue(List.filled(201, 'x').join()), isNotNull);
      expect(abtoEventNameIssue(List.filled(101, '🙂').join()), isNotNull);
    });
  });

  group('trace request id join', () {
    test('attachRequestIdFromHeaders reads header case-insensitively', () {
      covers('transport.request_id_header_case_insensitive');
      final client = AbtoClient(AbtoConfig(projectKey: 'ek_test'));
      final trace = client.startLlmTrace(featureId: 'smoke.demo');
      expect(trace.featureId, 'smoke.demo');
      expect(trace.traceId,
          matches(RegExp(r'^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$')));
      expect(trace.attachRequestIdFromHeaders({'X-Abto-Request-Id': 'req_1'}),
          'req_1');
      expect(trace.requestId, 'req_1');
    });
  });

  group('transport result handling', () {
    test('retries only events marked retry or omitted from a 202 response',
        () async {
      covers('transport.retry_marked_events_only');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requestBatches = <List<dynamic>>[];
      var requestCount = 0;
      final secondRequest = Completer<void>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        final batch = body['batch'] as List<dynamic>;
        requestBatches.add(batch);
        requestCount += 1;
        if (requestCount == 2 && !secondRequest.isCompleted) {
          secondRequest.complete();
        }
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {
                'result':
                    requestCount == 1 && event['event_id'] == 'retry-event'
                        ? 'retry'
                        : 'ok',
                if (requestCount == 1 && event['event_id'] == 'retry-event')
                  'code': 'storage_unavailable',
              },
          },
        }));
        await request.response.close();
      });

      try {
        final transport = AbtoTransport(
          AbtoConfig(
            projectKey: 'ek_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
            flushInterval: const Duration(milliseconds: 10),
          ),
        );
        transport.enqueue({'event_id': 'retry-event'});
        transport.enqueue({'event_id': 'ok-event'});

        await transport.flush();
        await secondRequest.future.timeout(const Duration(seconds: 5));

        expect(requestBatches, hasLength(2));
        expect(
          requestBatches[0].map((event) => event['event_id']),
          ['retry-event', 'ok-event'],
        );
        expect(
          requestBatches[1].map((event) => event['event_id']),
          ['retry-event'],
        );
      } finally {
        await server.close(force: true);
      }
    });

    test('omits non-finite metric values before JSON encoding', () async {
      covers('event.metric_non_finite_rejected');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        if (!received.isCompleted) received.complete(body);
        final batch = body['batch'] as List<dynamic>;
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'ok'},
          },
        }));
        await request.response.close();
      });

      try {
        final client = AbtoClient(
          AbtoConfig(
            projectKey: 'ek_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
          ),
        );
        client.capture('invalid_metric', value: double.nan, scale: 'count');
        client.capture('probe', value: 1, scale: 'count');
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final event =
            (body['batch'] as List<dynamic>).single as Map<String, dynamic>;
        expect(event['event_name'], 'probe');
        expect(event['value'], 1);
      } finally {
        await server.close(force: true);
      }
    });

    test('enforces metric precision and keeps promoted fields out of the bag',
        () async {
      covers('event.metric_precision_enforced');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        if (!received.isCompleted) received.complete(body);
        final batch = body['batch'] as List<dynamic>;
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'ok'},
          },
        }));
        await request.response.close();
      });

      try {
        final client = AbtoClient(
          AbtoConfig(
            projectKey: 'ek_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
          ),
        );
        client.identify('real-user', 'real-tenant');
        client.capture('bounded_metric',
            value: 1 / 3, scale: List.filled(17, 'x').join());
        client.capture('bad_scale',
            value: 1, scale: List.filled(17, 'x').join());
        client.capture('bad_properties',
            value: 1, scale: 'count', properties: {r'$user_id': 'spoof'});
        client.capture('probe', value: 1, scale: 'count');
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final event =
            (body['batch'] as List<dynamic>).single as Map<String, dynamic>;
        expect(event.containsKey('trace_id'), isFalse);
        expect(event['event_name'], 'probe');
        expect(event['value'], 1);
        expect(event['scale'], 'count');
        final extraJson = event['extra_json'] as Map<String, dynamic>;
        expect(extraJson[r'$environment'], 'development');
        expect(extraJson[r'$user_id'], 'real-user');
        expect(extraJson.containsKey(r'$trace_id'), isFalse);
        expect(extraJson.containsKey(r'$device_id'), isFalse);
        expect(extraJson.containsKey(r'$anonymous_id'), isFalse);
        expect(extraJson.containsKey(r'$session_id'), isFalse);
      } finally {
        await server.close(force: true);
      }
    });

    test('custom properties are stored separately from optional metrics',
        () async {
      covers('event.optional_scale_preserved');
      covers('event.properties_in_extra_json');
      covers('event.promoted_fields_not_in_extra_json');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        if (!received.isCompleted) received.complete(body);
        final batch = body['batch'] as List<dynamic>;
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'ok'},
          },
        }));
        await request.response.close();
      });

      try {
        final client = AbtoClient(
          AbtoConfig(
            projectKey: 'ek_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
          ),
        );
        client.capture('checkout_completed',
            value: 49000,
            scale: 'KRW',
            properties: {
              'tier': 'pro',
              'nullable': null,
              'tags': ['a'],
              'detail': {'enabled': true}
            });
        client.capture('scale_omitted', value: 0);
        client.capture('scale_empty', value: 0, scale: '');
        covers('event.optional_metrics_preserved');
        client.capture('name_only');
        client.capture('properties_only', properties: {'tier': 'pro'});
        client.capture('scale_only', scale: 'KRW');
        client.capture('scale_only_empty', scale: '');
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final batch = body['batch'] as List<dynamic>;
        expect(batch, hasLength(7));
        for (final item in batch.skip(3)) {
          final event = item as Map;
          expect(event.containsKey('value'), isFalse);
          final name = event['event_name'];
          if (name == 'scale_only') { expect(event['scale'], 'KRW'); }
          else if (name == 'scale_only_empty') { expect(event['scale'], ''); }
          else { expect(event.containsKey('scale'), isFalse); }
          final extra = event['extra_json'] as Map;
          expect(extra.containsKey('value'), isFalse);
          expect(extra.containsKey('scale'), isFalse);
          if (name == 'properties_only') expect(extra['tier'], 'pro');
        }
        expect((batch[1] as Map).containsKey('scale'), isFalse);
        expect((batch[2] as Map)['scale'], '');
        final event = batch.first as Map<String, dynamic>;
        expect(event['value'], 49000);
        expect(event['scale'], 'KRW');
        expect(event['device_id'], isA<String>());
        expect(event['session_id'], isA<String>());
        final extraJson = event['extra_json'] as Map<String, dynamic>;
        expect(extraJson['tier'], 'pro');
        expect(extraJson['nullable'], isNull);
        expect(extraJson.containsKey('nullable'), isTrue);
        expect(extraJson['tags'], ['a']);
        expect(extraJson['detail'], {'enabled': true});
        expect(extraJson.containsKey('properties'), isFalse);
        for (final key in [
          'value',
          'scale',
          r'$device_id',
          r'$anonymous_id',
          r'$session_id',
        ]) {
          expect(extraJson.containsKey(key), isFalse, reason: key);
        }
      } finally {
        await server.close(force: true);
      }
    });

    test('serializes canonical LLM helpers without prompt or response text',
        () async {
      covers('privacy.prompt_and_response_text_not_sent');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final received = Completer<Map<String, dynamic>>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        if (!received.isCompleted) received.complete(body);
        final batch = body['batch'] as List<dynamic>;
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'ok'},
          },
        }));
        await request.response.close();
      });

      try {
        final client = AbtoClient(AbtoConfig(
          projectKey: 'ek_privacy',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
        ));
        final trace = client.startLlmTrace(
            featureId: 'assistant.reply', taskType: 'answer');
        trace.submitPrompt(prompt: 'prompt-canary', language: 'en');
        trace.attach('req_helper');
        trace.markResponseVisible(
            responseId: 'response-1',
            responseText: 'response-canary',
            timeToVisibleMs: 42);
        trace.captureOutcome(AbtoResponseInteraction.copied,
            responseId: 'response-1');
        trace.captureOutcome('retried', responseId: 'response-1');
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final events =
            (body['batch'] as List<dynamic>).cast<Map<String, dynamic>>();
        expect(
          events.map((event) => event['event_name']),
          [
            'llm_prompt_submitted',
            'llm_response_rendered',
            'llm_response_interacted',
          ],
        );
        final prompt = events[0]['extra_json'] as Map<String, dynamic>;
        final rendered = events[1]['extra_json'] as Map<String, dynamic>;
        final interacted = events[2]['extra_json'] as Map<String, dynamic>;
        final encoded = jsonEncode(body);
        expect(encoded, isNot(contains('prompt-canary')));
        expect(encoded, isNot(contains('response-canary')));
        expect(prompt[r'$capture_mode'], 'metadata_only');
        expect(prompt[r'$prompt_length_chars'], 13);
        expect(prompt[r'$language'], 'en');
        expect(rendered[r'$capture_mode'], 'metadata_only');
        expect(rendered[r'$response_id'], 'response-1');
        expect(rendered[r'$output_length_chars'], 15);
        expect(rendered[r'$time_to_render_ms'], 42);
        expect(interacted[r'$interaction_type'], 'copied');
        expect(encoded, isNot(contains('retried')));
        expect(interacted[r'$request_id'], 'req_helper');
      } finally {
        await server.close(force: true);
      }
    });

    test('bounds collector response bodies before retrying', () async {
      covers('transport.response_body_cap');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requestCount = 0;
      final retried = Completer<void>();
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        final batch = body['batch'] as List<dynamic>;
        requestCount += 1;
        request.response.statusCode = HttpStatus.accepted;
        if (requestCount == 1) {
          request.response.add(List<int>.filled(64 * 1024 + 1, 65));
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'results': {
              for (final event in batch)
                event['event_id'] as String: {'result': 'ok'},
            },
          }));
          if (!retried.isCompleted) retried.complete();
        }
        await request.response.close();
      });

      try {
        final transport = AbtoTransport(AbtoConfig(
          projectKey: 'ek_bounded_response',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
          flushInterval: const Duration(milliseconds: 2),
        ));
        transport.enqueue({'event_id': 'bounded-response-event'});
        await transport.flush();
        await retried.future.timeout(const Duration(seconds: 5));
        expect(requestCount, 2);
      } finally {
        await server.close(force: true);
      }
    });

    test('stops retrying after the per-event attempt budget', () async {
      covers('transport.attempt_budget_stops_retry');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requestCount = 0;
      server.listen((request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        final batch = body['batch'] as List<dynamic>;
        requestCount += 1;
        request.response.statusCode = HttpStatus.accepted;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'results': {
            for (final event in batch)
              event['event_id'] as String: {'result': 'retry'},
          },
        }));
        await request.response.close();
      });

      try {
        final transport = AbtoTransport(AbtoConfig(
          projectKey: 'ek_retry_budget',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
          flushInterval: const Duration(milliseconds: 2),
        ));
        transport.enqueue({'event_id': 'retry-event'});
        await transport.flush();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(requestCount, abtoMaxAttempts);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(requestCount, abtoMaxAttempts);
      } finally {
        await server.close(force: true);
      }
    });
  });

  group('collector e2e', () {
    test('first event reaches local collector', () async {
      final client = AbtoClient(
        AbtoConfig(
          projectKey:
              Platform.environment['ABTO_E2E_KEY'] ?? 'ek_smoke_flutter',
          endpoint: Platform.environment['ABTO_E2E_ENDPOINT'] ??
              'http://localhost:4870/v1/collect/events',
          environment: AbtoEnvironment.development,
        ),
      );
      client.capture('sdk_e2e_flutter_currency',
          value: 49000, scale: 'KRW', properties: {'tier': 'pro'});
      client.capture('sdk_e2e_flutter_omitted', value: 0);
      client.capture('sdk_e2e_flutter_empty', value: 0, scale: '');
      client.capture('sdk_e2e_flutter_name_only');
      client.capture('sdk_e2e_flutter_properties_only', properties: {'tier': 'pro'});
      client.capture('sdk_e2e_flutter_scale_only', scale: 'KRW');
      client.capture('sdk_e2e_flutter_scale_only_empty', scale: '');
      client.identify('u_smoke_flutter');
      final trace = client.startLlmTrace(
          featureId: 'smoke.flutter',
          taskType: 'smoke_test',
          surface: 'dart_test');
      trace.submitPrompt(prompt: 'Flutter 스모크 프롬프트', language: 'ko');
      trace.attach('req_smoke_flutter');
      trace.markResponseVisible(
          responseId: 'resp_smoke_flutter',
          responseText: 'Flutter 응답',
          timeToVisibleMs: 42);
      trace.captureOutcome(AbtoResponseInteraction.copied,
          responseId: 'resp_smoke_flutter');
      await client.flush();
    },
        skip: Platform.environment['ABTO_E2E'] == '1'
            ? false
            : 'set ABTO_E2E=1 with dev collector running');
  });
}
