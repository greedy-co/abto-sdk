import Foundation

/// 이벤트 스키마 버전 — 브라우저 SDK(packages/sdk)와 동일한 계약을 따른다.
public let abtoSchemaVersion = "2026-06-24"

public enum AbtoEnvironment: String {
    case development
    case staging
    case production
}

public enum AbtoInitError: Error, CustomStringConvertible, LocalizedError {
    case invalidConfig(String)

    public var description: String {
        switch self {
        case .invalidConfig(let message): return message
        }
    }

    public var errorDescription: String? { description }
}

public struct AbtoConfig {
    public let projectKey: String
    public let endpoint: URL
    public let environment: AbtoEnvironment
    public let debug: Bool
    public let batchSize: Int
    public let flushInterval: TimeInterval

    public init(
        projectKey: String,
        endpoint: String? = nil,
        environment: AbtoEnvironment = .production,
        debug: Bool? = nil,
        batchSize: Int = 20,
        flushInterval: TimeInterval = 5.0
    ) throws {
        guard !projectKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AbtoInitError.invalidConfig("[abto] projectKey is required. Check your init config.")
        }
        let rawEndpoint = endpoint ?? "https://api.abto.ai/v1/events"
        // fetch 가능한 endpoint 여야 하므로 http(s) 만 허용한다 (브라우저 SDK 와 동일한 검증).
        guard let url = URL(string: rawEndpoint),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            throw AbtoInitError.invalidConfig("[abto] endpoint is not a valid http(s) URL: \"\(rawEndpoint)\"")
        }
        self.projectKey = projectKey
        self.endpoint = url
        self.environment = environment
        self.debug = debug ?? (environment == .development)
        self.batchSize = batchSize
        self.flushInterval = flushInterval
    }
}
