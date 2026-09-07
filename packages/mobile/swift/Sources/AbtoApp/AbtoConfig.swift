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
        batchSize: Int = abtoDefaultBatchSize,
        flushInterval: TimeInterval = abtoDefaultFlushInterval
    ) throws {
        guard !projectKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AbtoInitError.invalidConfig(abtoErrProjectKeyRequired)
        }
        guard (abtoMinBatchSize...abtoMaxBatchSize).contains(batchSize) else {
            throw AbtoInitError.invalidConfig(abtoErrBatchSizeRange)
        }
        let rawEndpoint = endpoint ?? abtoDefaultCollectEndpoint
        // Allow only HTTP(S) endpoints, matching Browser SDK validation.
        guard let url = URL(string: rawEndpoint),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil,
              url.user == nil,
              url.password == nil
        else {
            throw AbtoInitError.invalidConfig("\(abtoErrEndpointInvalidPrefix)\"\(rawEndpoint)\"")
        }
        let host = url.host?.lowercased()
        let developmentLoopback = environment == .development
            && (abtoLoopbackHosts.contains(host ?? "") || abtoLoopbackHostPrefixes.contains { host?.hasPrefix($0) == true })
        guard scheme == "https" || developmentLoopback else {
            throw AbtoInitError.invalidConfig(abtoErrEndpointHTTPSRequired)
        }
        self.projectKey = projectKey
        self.endpoint = url
        self.environment = environment
        self.debug = debug ?? (environment == .development)
        self.batchSize = batchSize
        self.flushInterval = flushInterval
    }
}
