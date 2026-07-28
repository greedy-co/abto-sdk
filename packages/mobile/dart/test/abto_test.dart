import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:abto/abto.dart';
import 'package:abto/src/transport.dart';
import 'package:test/test.dart';

final uuidV7Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

void main() {
  group('init config validation', () {
    test('accepts a minimal valid config', () {
      final config = AbtoConfig(projectKey: 'pk_test');
      expect(
          config.endpoint.toString(), 'https://api.abto.app/v1/collect/events');
      expect(config.environment, AbtoEnvironment.production);
      expect(config.debug, isFalse);
    });

    test('development turns debug on', () {
      expect(
          AbtoConfig(projectKey: 'pk', environment: AbtoEnvironment.development)
              .debug,
          isTrue);
    });

    test('rejects an empty projectKey', () {
      expect(
        () => AbtoConfig(projectKey: '  '),
        throwsA(predicate((e) =>
            e.toString() ==
            '[abto] projectKey is required. Check your init config.')),
      );
    });

    test('rejects a malformed endpoint', () {
      expect(
        () => AbtoConfig(projectKey: 'pk', endpoint: 'htp:/broken url'),
        throwsA(predicate((e) => e
            .toString()
            .startsWith('[abto] endpoint is not a valid http(s) URL:'))),
      );
    });

    test('requires HTTPS outside development loopback', () {
      expect(
        () => AbtoConfig(
            projectKey: 'pk',
            endpoint: 'http://collector.example/v1/collect/events'),
        throwsA(predicate((e) =>
            e.toString() ==
            '[abto] endpoint must use HTTPS outside development loopback.')),
      );
      expect(
        AbtoConfig(
          projectKey: 'pk',
          endpoint: 'http://127.0.0.1:4870/v1/collect/events',
          environment: AbtoEnvironment.development,
        ).endpoint.scheme,
        'http',
      );
    });

    test('rejects batch sizes outside the collector limit', () {
      expect(
        () => AbtoConfig(projectKey: 'pk', batchSize: 0),
        throwsA(predicate((e) =>
            e.toString() == '[abto] batchSize must be between 1 and 100.')),
      );
      expect(
        () => AbtoConfig(projectKey: 'pk', batchSize: 101),
        throwsA(predicate((e) =>
            e.toString() == '[abto] batchSize must be between 1 and 100.')),
      );
    });
  });

  group('context identity', () {
    test('anonymous_id persists across clients, session_id rotates', () {
      final store = AbtoInMemoryStore();
      final first = AbtoContext(store);
      final second = AbtoContext(store);
      expect(first.anonymousId, second.anonymousId);
      expect(first.anonymousId, matches(uuidV7Pattern));
      expect(first.sessionId, matches(uuidV7Pattern));
      expect(first.sessionId, isNot(second.sessionId));
    });

    test('identify and reset', () {
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
        AbtoConfig(projectKey: 'pk_test'),
        store: AbtoInMemoryStore(),
      );
      final beforeReset = client.deviceId;
      expect(beforeReset, matches(uuidV7Pattern));
      expect(client.sessionId, matches(uuidV7Pattern));
      client.reset();
      expect(client.deviceId, isNot(beforeReset));
    });

    test('rejects overlong event names with Backend UTF-16 semantics', () {
      final client = AbtoClient(AbtoConfig(projectKey: 'pk_test'));
      expect(client.capture('pageview'), isFalse);
      expect(client.capture(List.filled(201, 'x').join()), isFalse);
      expect(client.capture(List.filled(101, '🙂').join()), isFalse);
    });
  });

  group('trace request id join', () {
    test('attachRequestIdFromHeaders reads header case-insensitively', () {
      final client = AbtoClient(AbtoConfig(projectKey: 'pk_test'));
      final trace = client.startLlmTrace(nodeId: 'smoke.demo');
      expect(trace.traceId,
          matches(RegExp(r'^[0-9a-f]{12}7[0-9a-f]{3}[89ab][0-9a-f]{15}$')));
      expect(
          trace.attachRequestIdFromHeaders({'X-Request-Id': 'req_1'}), 'req_1');
      expect(trace.requestId, 'req_1');
    });
  });

  group('transport result handling', () {
    test('retries only events marked retry or omitted from a 202 response',
        () async {
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
            projectKey: 'pk_test',
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
            projectKey: 'pk_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
          ),
        );
        client.capture('invalid_metric', value: double.nan);
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final event =
            (body['batch'] as List<dynamic>).single as Map<String, dynamic>;
        expect(event.containsKey('value'), isFalse);
      } finally {
        await server.close(force: true);
      }
    });

    test('enforces metric precision and protects SDK context', () async {
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
            projectKey: 'pk_test',
            endpoint:
                'http://${server.address.host}:${server.port}/v1/collect/events',
            environment: AbtoEnvironment.development,
          ),
        );
        client.identify('real-user', 'real-tenant');
        client.capture(
          'bounded_metric',
          value: 1 / 3,
          scale: List.filled(17, 'x').join(),
          envelope: {
            'trace_id': ['invalid', 'trace'],
            'node_id': 'node.real',
          },
          properties: {
            'environment': 'customer-environment',
            'user_id': 'customer-user',
            r'$environment': 'spoofed',
            r'$user_id': 'spoofed',
          },
        );
        await client.flush();

        final body = await received.future.timeout(const Duration(seconds: 5));
        final event =
            (body['batch'] as List<dynamic>).single as Map<String, dynamic>;
        expect(event.containsKey('trace_id'), isFalse);
        expect(event.containsKey('value'), isFalse);
        expect(event.containsKey('scale'), isFalse);
        final extraJson = event['extra_json'] as Map<String, dynamic>;
        expect(extraJson['environment'], 'customer-environment');
        expect(extraJson['user_id'], 'customer-user');
        expect(extraJson[r'$environment'], 'development');
        expect(extraJson[r'$user_id'], 'real-user');
        expect(extraJson.containsKey(r'$trace_id'), isFalse);
        expect(extraJson[r'$node_key'], 'node.real');
        expect(extraJson.values, isNot(contains('spoofed')));
      } finally {
        await server.close(force: true);
      }
    });

    test('serializes canonical LLM helpers without prompt or response text',
        () async {
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
          projectKey: 'pk_privacy',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
        ));
        final trace =
            client.startLlmTrace(nodeId: 'assistant.reply', taskType: 'answer');
        trace.submitPrompt(prompt: 'prompt-canary', language: 'en');
        trace.attach('req_helper');
        trace.markResponseVisible(
            responseId: 'response-1',
            responseText: 'response-canary',
            timeToVisibleMs: 42);
        trace.captureOutcome('copied', responseId: 'response-1');
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
        expect(interacted[r'$request_id'], 'req_helper');
      } finally {
        await server.close(force: true);
      }
    });

    test('bounds collector response bodies before retrying', () async {
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
          projectKey: 'pk_bounded_response',
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
          projectKey: 'pk_retry_budget',
          endpoint:
              'http://${server.address.host}:${server.port}/v1/collect/events',
          environment: AbtoEnvironment.development,
          flushInterval: const Duration(milliseconds: 2),
        ));
        transport.enqueue({'event_id': 'retry-event'});
        await transport.flush();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(requestCount, 3);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(requestCount, 3);
      } finally {
        await server.close(force: true);
      }
    });
  });

  group('collector e2e', () {
    test('first event reaches local collector', () async {
      final client = AbtoClient(
        AbtoConfig(
          projectKey: 'pk_smoke_flutter',
          endpoint: 'http://localhost:4870/v1/collect/events',
          environment: AbtoEnvironment.development,
        ),
      );
      client.identify('u_smoke_flutter');
      final trace = client.startLlmTrace(
          nodeId: 'smoke.flutter',
          taskType: 'smoke_test',
          surface: 'dart_test');
      trace.submitPrompt(prompt: 'Flutter 스모크 프롬프트', language: 'ko');
      trace.attach('req_smoke_flutter');
      trace.markResponseVisible(
          responseId: 'resp_smoke_flutter',
          responseText: 'Flutter 응답',
          timeToVisibleMs: 42);
      trace.captureOutcome('copied', responseId: 'resp_smoke_flutter');
      await client.flush();
    },
        skip: Platform.environment['ABTO_E2E'] == '1'
            ? false
            : 'set ABTO_E2E=1 with dev collector running');
  });
}
