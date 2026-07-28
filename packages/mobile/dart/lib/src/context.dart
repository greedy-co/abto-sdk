import 'dart:math';

final _random = Random.secure();

String randomHex(int byteCount) => List.generate(byteCount,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

String uuidV7([DateTime? date]) {
  final milliseconds = (date ?? DateTime.now()).millisecondsSinceEpoch;
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  for (var index = 0; index < 6; index++) {
    bytes[index] = (milliseconds >> ((5 - index) * 8)) & 0xff;
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x70;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

String uuidV7TraceId() => uuidV7().replaceAll('-', '');

String isoTimestamp() => DateTime.now().toUtc().toIso8601String();

/// anonymous_id 영속화 지점 — Flutter 에선 shared_preferences 어댑터를 끼우고,
/// 테스트에선 인메모리 구현을 쓴다 (README 참고).
abstract class AbtoKeyValueStore {
  String? get(String key);
  void set(String key, String value);
}

class AbtoInMemoryStore implements AbtoKeyValueStore {
  final _values = <String, String>{};

  @override
  String? get(String key) => _values[key];

  @override
  void set(String key, String value) => _values[key] = value;
}

/// 식별자 컨텍스트 — 이벤트 공통 필드(anonymous_id·session_id·user_id·tenant_id)를 관리한다.
class AbtoContext {
  AbtoContext(this._store) {
    final existing = _store.get(_anonymousIdKey);
    if (existing != null) {
      anonymousId = existing;
    } else {
      anonymousId = uuidV7();
      _store.set(_anonymousIdKey, anonymousId);
    }
    sessionId = uuidV7();
  }

  static const _anonymousIdKey = 'abto_anonymous_id';

  final AbtoKeyValueStore _store;
  late String anonymousId;
  late String sessionId;
  String? userId;
  String? tenantId;

  void identify(String userId, [String? tenantId]) {
    this.userId = userId;
    this.tenantId = tenantId;
  }

  void reset() {
    userId = null;
    tenantId = null;
    anonymousId = uuidV7();
    _store.set(_anonymousIdKey, anonymousId);
    sessionId = uuidV7();
  }

  Map<String, Object> commonProperties() => {
        'anonymous_id': anonymousId,
        'session_id': sessionId,
        if (userId != null) 'user_id': userId!,
        if (tenantId != null) 'tenant_id': tenantId!,
      };
}
