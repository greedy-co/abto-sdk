package app.abto.sdk

import java.security.SecureRandom
import java.time.Instant

private val random = SecureRandom()

internal fun randomHex(byteCount: Int): String {
    val bytes = ByteArray(byteCount)
    random.nextBytes(bytes)
    return bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
}

internal fun uuidV7(now: Long = System.currentTimeMillis()): String {
    val bytes = ByteArray(16)
    random.nextBytes(bytes)
    for (index in 0..5) {
        bytes[index] = (now ushr ((5 - index) * 8)).toByte()
    }
    bytes[6] = ((bytes[6].toInt() and 0x0f) or 0x70).toByte()
    bytes[8] = ((bytes[8].toInt() and 0x3f) or 0x80).toByte()
    val hex = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
    return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}"
}

internal fun uuidV7TraceId(): String = uuidV7().replace("-", "")

internal fun isoTimestamp(): String = Instant.now().toString()

/**
 * anonymous_id 영속화 지점 — Android 에선 SharedPreferences 어댑터를 끼우고,
 * JVM 테스트에선 인메모리 구현을 쓴다 (README 참고).
 */
interface AbtoKeyValueStore {
    fun get(key: String): String?
    fun set(key: String, value: String)
}

class AbtoInMemoryStore : AbtoKeyValueStore {
    private val values = mutableMapOf<String, String>()

    override fun get(key: String): String? = values[key]
    override fun set(key: String, value: String) {
        values[key] = value
    }
}

/** 식별자 컨텍스트 — 이벤트 공통 필드(anonymous_id·session_id·user_id·tenant_id)를 관리한다. */
class AbtoContext(private val store: AbtoKeyValueStore) {
    var anonymousId: String
        private set
    var sessionId: String
        private set
    var userId: String? = null
        private set
    var tenantId: String? = null
        private set

    init {
        anonymousId = store.get(ANONYMOUS_ID_KEY) ?: uuidV7().also {
            store.set(ANONYMOUS_ID_KEY, it)
        }
        sessionId = uuidV7()
    }

    fun identify(userId: String, tenantId: String? = null) {
        this.userId = userId
        this.tenantId = tenantId
    }

    fun reset() {
        userId = null
        tenantId = null
        anonymousId = uuidV7()
        store.set(ANONYMOUS_ID_KEY, anonymousId)
        sessionId = uuidV7()
    }

    fun commonProperties(): Map<String, Any> = buildMap {
        put("anonymous_id", anonymousId)
        put("session_id", sessionId)
        userId?.let { put("user_id", it) }
        tenantId?.let { put("tenant_id", it) }
    }

    private companion object {
        const val ANONYMOUS_ID_KEY = "abto_anonymous_id"
    }
}
