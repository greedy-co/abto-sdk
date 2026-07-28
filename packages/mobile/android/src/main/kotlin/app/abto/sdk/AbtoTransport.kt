package app.abto.sdk

import java.net.HttpURLConnection
import java.net.URI
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

internal fun readBoundedResponse(
    input: InputStream,
    maxBytes: Int = 64 * 1024,
): String {
    val output = ByteArrayOutputStream(minOf(maxBytes, 8 * 1024))
    val chunk = ByteArray(8 * 1024)
    var total = 0
    while (true) {
        val read = input.read(chunk)
        if (read < 0) break
        total += read
        if (total > maxBytes) throw IOException("[abto] collector response exceeded $maxBytes bytes.")
        output.write(chunk, 0, read)
    }
    return output.toString(Charsets.UTF_8)
}

/**
 * 배치 전송 — 큐에 쌓고 batchSize/타이머로 flush 한다.
 * 네트워크는 항상 전용 스레드에서 돌아 Android 메인 스레드 제약(NetworkOnMainThreadException)을 피하고,
 * 실패는 절대 호스트 앱으로 던지지 않는다 (브라우저 SDK 와 동일 계약).
 */
class AbtoTransport(private val config: AbtoConfig) {
    private val lock = Any()
    private val buffer = ArrayDeque<Map<String, Any?>>()
    private val executor = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "abto-transport").apply { isDaemon = true }
    }
    private var scheduledFlush: ScheduledFuture<*>? = null

    fun enqueue(event: Map<String, Any?>) {
        val shouldFlushNow: Boolean
        synchronized(lock) {
            buffer.addLast(event)
            shouldFlushNow = buffer.size >= config.batchSize
            if (!shouldFlushNow && scheduledFlush == null) {
                scheduleFlushLocked(config.flushIntervalMs)
            }
        }
        if (shouldFlushNow) flush()
    }

    fun flush(onComplete: Runnable? = null) {
        executor.execute {
            drainAndSend()
            onComplete?.run()
        }
    }

    private fun drainAndSend() {
        val batch: List<Map<String, Any?>>
        synchronized(lock) {
            scheduledFlush?.cancel(false)
            scheduledFlush = null
            if (buffer.isEmpty()) return
            val count = minOf(buffer.size, config.batchSize, MAX_BATCH_SIZE)
            batch = List(count) { buffer.removeFirst() }
        }

        val body = AbtoJson.encode(mapOf("batch" to batch)).toByteArray(Charsets.UTF_8)
        val retryBatch = try {
            val connection = URI(config.endpoint).toURL().openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "POST"
                connection.doOutput = true
                connection.connectTimeout = 5_000
                connection.readTimeout = 5_000
                connection.setRequestProperty("content-type", "application/json")
                connection.setRequestProperty("authorization", "Bearer ${config.projectKey}")
                connection.outputStream.use { it.write(body) }
                val status = connection.responseCode
                if (isTransientStatus(status)) {
                    batch
                } else if (status >= 400) {
                    emptyList()
                } else {
                    val responseBody = connection.inputStream.use { readBoundedResponse(it) }
                    val eventIds = batch.mapNotNull { it["event_id"] as? String }
                    val retryIds = retryEventIds(responseBody, eventIds)
                    if (retryIds == null) batch else batch.filter { it["event_id"] !is String || it["event_id"] in retryIds }
                }
            } finally {
                connection.disconnect()
            }
        } catch (_: Exception) {
            batch
        }

        if (retryBatch.isNotEmpty()) {
            synchronized(lock) {
                // 죽은 endpoint 가 메모리를 무한히 키우지 않게 버퍼를 제한한다.
                retryBatch.asReversed().forEach { buffer.addFirst(it) }
                while (buffer.size > MAX_BUFFER) buffer.removeLast()
                scheduleFlushLocked(config.flushIntervalMs)
            }
        } else {
            synchronized(lock) {
                if (buffer.isNotEmpty()) scheduleFlushLocked(0)
            }
        }
    }

    private fun scheduleFlushLocked(delayMs: Long) {
        if (scheduledFlush != null) return
        scheduledFlush = executor.schedule({ drainAndSend() }, delayMs, TimeUnit.MILLISECONDS)
    }

    private companion object {
        const val MAX_BUFFER = 1000
        const val MAX_BATCH_SIZE = 100
        val ACK_RESULTS = setOf("ok", "warning", "drop")
        val RESULT_PATTERN = Regex(""""result"\s*:\s*"([^"]+)"""")

        fun isTransientStatus(status: Int): Boolean = status == 408 || status == 429 || status >= 500

        fun retryEventIds(responseBody: String, eventIds: List<String>): Set<String>? {
            if (!Regex(""""results"\s*:\s*\{""").containsMatchIn(responseBody)) return null
            return eventIds.filterTo(linkedSetOf()) { eventId ->
                val eventPattern = Regex(""""${Regex.escape(eventId)}"\s*:\s*\{""")
                val match = eventPattern.find(responseBody) ?: return@filterTo true
                val objectStart = responseBody.indexOf('{', match.range.first)
                val objectEnd = findObjectEnd(responseBody, objectStart)
                if (objectEnd == null) {
                    true
                } else {
                    val result = RESULT_PATTERN.find(responseBody.substring(objectStart, objectEnd + 1))
                        ?.groupValues
                        ?.get(1)
                    result !in ACK_RESULTS
                }
            }
        }

        fun findObjectEnd(json: String, start: Int): Int? {
            if (start !in json.indices || json[start] != '{') return null
            var depth = 0
            var inString = false
            var escaped = false
            for (index in start until json.length) {
                val ch = json[index]
                if (inString) {
                    when {
                        escaped -> escaped = false
                        ch == '\\' -> escaped = true
                        ch == '"' -> inString = false
                    }
                    continue
                }
                when (ch) {
                    '"' -> inString = true
                    '{' -> depth += 1
                    '}' -> {
                        depth -= 1
                        if (depth == 0) return index
                    }
                }
            }
            return null
        }
    }
}
