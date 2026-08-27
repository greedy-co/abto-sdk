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
    int batchSize = 20,
    Duration flushInterval = const Duration(seconds: 5),
  }) {
    if (projectKey.trim().isEmpty) {
      throw AbtoInitException(
          '[abto] projectKey is required. Check your init config.');
    }
    if (batchSize < 1 || batchSize > 100) {
      throw AbtoInitException('[abto] batchSize must be between 1 and 100.');
    }
    final raw = endpoint ?? 'https://api.abto.app/v1/collect/events';
    // Allow only HTTP(S) endpoints, matching Browser SDK validation.
    final parsed = Uri.tryParse(raw);
    if (parsed == null ||
        (parsed.scheme != 'http' && parsed.scheme != 'https') ||
        !parsed.hasAuthority ||
        parsed.userInfo.isNotEmpty) {
      throw AbtoInitException(
          '[abto] endpoint is not a valid http(s) URL: "$raw"');
    }
    final developmentLoopback = environment == AbtoEnvironment.development &&
        (parsed.host == 'localhost' ||
            parsed.host == '::1' ||
            parsed.host.startsWith('127.'));
    if (parsed.scheme == 'http' && !developmentLoopback) {
      throw AbtoInitException(
          '[abto] endpoint must use HTTPS outside development loopback.');
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
