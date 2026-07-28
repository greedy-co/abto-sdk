package app.abto.sdk

import java.net.URI

enum class AbtoEnvironment {
    DEVELOPMENT, STAGING, PRODUCTION;

    val wireName: String get() = name.lowercase()
}

class AbtoInitException(message: String) : IllegalArgumentException(message)

class AbtoConfig(
    val projectKey: String,
    endpoint: String? = null,
    val environment: AbtoEnvironment = AbtoEnvironment.PRODUCTION,
    debug: Boolean? = null,
    val batchSize: Int = 20,
    val flushIntervalMs: Long = 5_000,
) {
    val endpoint: String
    val debug: Boolean

    init {
        if (projectKey.isBlank()) {
            throw AbtoInitException("[abto] projectKey is required. Check your init config.")
        }
        if (batchSize !in 1..100) {
            throw AbtoInitException("[abto] batchSize must be between 1 and 100.")
        }
        val raw = endpoint ?: "https://api.abto.app/v1/collect/events"
        // fetch 가능한 endpoint 여야 하므로 http(s) 만 허용한다 (브라우저 SDK 와 동일한 검증).
        val parsed = try {
            URI(raw)
        } catch (_: Exception) {
            null
        }
        val scheme = parsed?.scheme?.lowercase()
        val host = parsed?.host?.lowercase()
        if ((scheme != "http" && scheme != "https") || host.isNullOrBlank()) {
            throw AbtoInitException("[abto] endpoint is not a valid http(s) URL: \"$raw\"")
        }
        val developmentLoopback =
            environment == AbtoEnvironment.DEVELOPMENT &&
                (host == "localhost" || host == "::1" || host.startsWith("127."))
        if (scheme == "http" && !developmentLoopback) {
            throw AbtoInitException("[abto] endpoint must use HTTPS outside development loopback.")
        }
        this.endpoint = raw
        this.debug = debug ?: (environment == AbtoEnvironment.DEVELOPMENT)
    }
}
