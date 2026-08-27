import Foundation

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
        guard (1...100).contains(batchSize) else {
            throw AbtoInitError.invalidConfig("[abto] batchSize must be between 1 and 100.")
        }
        let rawEndpoint = endpoint ?? "https://api.abto.app/v1/collect/events"
        // Allow only HTTP(S) endpoints, matching Browser SDK validation.
        guard let url = URL(string: rawEndpoint),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil,
              url.user == nil,
              url.password == nil
        else {
            throw AbtoInitError.invalidConfig("[abto] endpoint is not a valid http(s) URL: \"\(rawEndpoint)\"")
        }
        let host = url.host?.lowercased()
        let developmentLoopback = environment == .development
            && (host == "localhost" || host == "::1" || host?.hasPrefix("127.") == true)
        guard scheme == "https" || developmentLoopback else {
            throw AbtoInitError.invalidConfig("[abto] endpoint must use HTTPS outside development loopback.")
        }
        self.projectKey = projectKey
        self.endpoint = url
        self.environment = environment
        self.debug = debug ?? (environment == .development)
        self.batchSize = batchSize
        self.flushInterval = flushInterval
    }
}
