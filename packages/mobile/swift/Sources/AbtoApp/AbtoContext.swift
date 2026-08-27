import Foundation

func abtoRandomHex(_ byteCount: Int) -> String {
    (0..<byteCount).map { _ in String(format: "%02x", UInt8.random(in: 0...255)) }.joined()
}

func abtoUUIDv7(_ date: Date = Date()) -> String {
    let milliseconds = UInt64(date.timeIntervalSince1970 * 1_000)
    var bytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
    for index in 0..<6 {
        bytes[index] = UInt8((milliseconds >> UInt64((5 - index) * 8)) & 0xff)
    }
    bytes[6] = (bytes[6] & 0x0f) | 0x70
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    let hex = bytes.map { String(format: "%02x", $0) }.joined()
    return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
}

func abtoUUIDv7TraceId() -> String {
    abtoUUIDv7().replacingOccurrences(of: "-", with: "")
}

func abtoTimestamp() -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: Date())
}

/// Persistence boundary for `anonymous_id`. Defaults to UserDefaults; tests inject an in-memory store.
public protocol AbtoKeyValueStore {
    func string(forKey key: String) -> String?
    func setString(_ value: String, forKey key: String)
}

public final class AbtoUserDefaultsStore: AbtoKeyValueStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func string(forKey key: String) -> String? { defaults.string(forKey: key) }
    public func setString(_ value: String, forKey key: String) { defaults.set(value, forKey: key) }
}

public final class AbtoInMemoryStore: AbtoKeyValueStore {
    private var values: [String: String] = [:]

    public init() {}

    public func string(forKey key: String) -> String? { values[key] }
    public func setString(_ value: String, forKey key: String) { values[key] = value }
}

/// Identity context that manages shared event fields: anonymous_id, session_id, user_id, and tenant_id.
public final class AbtoContext {
    private static let anonymousIdKey = "abto_anonymous_id"

    private let store: AbtoKeyValueStore
    public private(set) var anonymousId: String
    public private(set) var sessionId: String
    public private(set) var userId: String?
    public private(set) var tenantId: String?

    public init(store: AbtoKeyValueStore) {
        self.store = store
        if let existing = store.string(forKey: Self.anonymousIdKey) {
            anonymousId = existing
        } else {
            anonymousId = abtoUUIDv7()
            store.setString(anonymousId, forKey: Self.anonymousIdKey)
        }
        sessionId = abtoUUIDv7()
    }

    public func identify(userId: String, tenantId: String? = nil) {
        self.userId = userId
        self.tenantId = tenantId
    }

    public func reset() {
        userId = nil
        tenantId = nil
        anonymousId = abtoUUIDv7()
        store.setString(anonymousId, forKey: Self.anonymousIdKey)
        sessionId = abtoUUIDv7()
    }

    public func commonProperties() -> [String: Any] {
        var common: [String: Any] = [
            "anonymous_id": anonymousId,
            "session_id": sessionId,
        ]
        if let userId { common["user_id"] = userId }
        if let tenantId { common["tenant_id"] = tenantId }
        return common
    }
}
