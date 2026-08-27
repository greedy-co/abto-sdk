package app.abto.sdk

/** Minimal JSON encoder for serializing event payloads without external dependencies. */
internal object AbtoJson {
    fun encode(value: Any?): String = when (value) {
        null -> "null"
        is String -> encodeString(value)
        is Boolean, is Int, is Long, is Double, is Float -> value.toString()
        is Map<*, *> -> value.entries.joinToString(",", "{", "}") { (k, v) ->
            "${encodeString(k.toString())}:${encode(v)}"
        }
        is List<*> -> value.joinToString(",", "[", "]") { encode(it) }
        else -> encodeString(value.toString())
    }

    private fun encodeString(value: String): String {
        val sb = StringBuilder("\"")
        for (ch in value) {
            when (ch) {
                '"' -> sb.append("\\\"")
                '\\' -> sb.append("\\\\")
                '\n' -> sb.append("\\n")
                '\r' -> sb.append("\\r")
                '\t' -> sb.append("\\t")
                else -> if (ch < ' ') sb.append("\\u%04x".format(ch.code)) else sb.append(ch)
            }
        }
        return sb.append('"').toString()
    }
}
