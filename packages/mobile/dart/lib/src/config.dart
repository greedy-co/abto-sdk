import 'contract.generated.dart';

enum AbtoEnvironment {
  development,
  staging,
  production;

  String get wireName => name;
}

class AbtoInitException implements Exception {
  AbtoInitException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AbtoConfig {
  factory AbtoConfig({
    required String projectKey,
    String? endpoint,
    AbtoEnvironment environment = AbtoEnvironment.production,
    bool? debug,
    int batchSize = abtoDefaultBatchSize,
    Duration flushInterval = abtoDefaultFlushInterval,
  }) {
    if (projectKey.trim().isEmpty) {
      throw AbtoInitException(
          abtoErrProjectKeyRequired);
    }
    if (batchSize < abtoMinBatchSize || batchSize > abtoMaxBatchSize) {
      throw AbtoInitException(abtoErrBatchSizeRange);
    }
    final raw = endpoint ?? abtoDefaultCollectEndpoint;
    // Allow only HTTP(S) endpoints, matching Browser SDK validation.
    final parsed = Uri.tryParse(raw);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
        !parsed.hasAuthority ||
        parsed.userInfo.isNotEmpty) {
      throw AbtoInitException(
          '$abtoErrEndpointInvalidPrefix"$raw"');
    }
    final developmentLoopback = environment == AbtoEnvironment.development &&
        (parsed.host == 'localhost' ||
            parsed.host == '::1' ||
            parsed.host.startsWith('127.'));
    if (parsed.scheme == 'http' && !developmentLoopback) {
      throw AbtoInitException(
          abtoErrEndpointHttpsRequired);
    }
    return AbtoConfig._(
      projectKey: projectKey,
      endpoint: parsed,
      environment: environment,
      debug: debug ?? (environment == AbtoEnvironment.development),
      batchSize: batchSize,
      flushInterval: flushInterval,
    );
  }

  AbtoConfig._({
    required this.projectKey,
    required this.endpoint,
    required this.environment,
    required this.debug,
    required this.batchSize,
    required this.flushInterval,
  });

  final String projectKey;
  final Uri endpoint;
  final AbtoEnvironment environment;
  final bool debug;
  final int batchSize;
  final Duration flushInterval;
}
