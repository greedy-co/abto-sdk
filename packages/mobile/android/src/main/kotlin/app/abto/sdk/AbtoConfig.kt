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
    val batchSize: Int = ABTO_DEFAULT_BATCH_SIZE,
    val flushIntervalMs: Long = ABTO_DEFAULT_FLUSH_INTERVAL_MS,
) {
    val endpoint: String
    val debug: Boolean

    init {
        if (projectKey.isBlank()) {
            throw AbtoInitException(ABTO_ERR_PROJECT_KEY_REQUIRED)
        }
        if (batchSize !in ABTO_MIN_BATCH_SIZE..ABTO_MAX_BATCH_SIZE) {
            throw AbtoInitException(ABTO_ERR_BATCH_SIZE_RANGE)
        }
        val raw = endpoint ?: ABTO_DEFAULT_COLLECT_ENDPOINT
        // Allow only HTTP(S) endpoints, matching Browser SDK validation.
        val parsed = try {
            URI(raw)
        } catch (_: Exception) {
            null
        }
        val scheme = parsed?.scheme?.lowercase()
        val host = parsed?.host?.lowercase()
        if ((scheme != "http" && scheme != "https") || host.isNullOrBlank()) {
            throw AbtoInitException("$ABTO_ERR_ENDPOINT_INVALID_PREFIX\"$raw\"")
        }
        val developmentLoopback =
            environment == AbtoEnvironment.DEVELOPMENT &&
                (host in ABTO_LOOPBACK_HOSTS || ABTO_LOOPBACK_HOST_PREFIXES.any { host.startsWith(it) })
        if (scheme == "http" && !developmentLoopback) {
            throw AbtoInitException(ABTO_ERR_ENDPOINT_HTTPS_REQUIRED)
        }
        this.endpoint = raw
        this.debug = debug ?: (environment == AbtoEnvironment.DEVELOPMENT)
    }
}
