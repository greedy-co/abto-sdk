package app.abto.sdk

import java.net.HttpURLConnection
import java.net.URI
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStream
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.ThreadLocalRandom
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
 * Batch transport that queues events and flushes on `batchSize` or a timer.
 * Network operations always run on a dedicated thread to avoid Android main-thread restrictions
 * (`NetworkOnMainThreadException`), and failures are never thrown to the host app, matching the Browser SDK contract.
 */
class AbtoTransport(private val config: AbtoConfig) {
    private data class QueuedEvent(
        val event: Map<String, Any?>,
        val firstQueuedAtMs: Long = System.currentTimeMillis(),
        var attempts: Int = 0,
    )

    private val lock = Any()
    private val buffer = ArrayDeque<QueuedEvent>()
    private val executor = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "abto-transport").apply { isDaemon = true }
    }
    private var scheduledFlush: ScheduledFuture<*>? = null
    private var flushRunning = false
    private var flushRequested = false
    private val pendingCompletions = ArrayDeque<Runnable>()

    fun enqueue(event: Map<String, Any?>) {
        synchronized(lock) {
            buffer.addLast(QueuedEvent(event))
            while (buffer.size > MAX_BUFFER) buffer.removeFirst()
            if (buffer.size >= config.batchSize) {
                requestFlushLocked(0)
            } else {
                scheduleFlushLocked(config.flushIntervalMs)
            }
        }
    }

    fun flush(onComplete: Runnable? = null) {
        synchronized(lock) {
            onComplete?.let(pendingCompletions::addLast)
            requestFlushLocked(0)
        }
    }

    private fun runScheduledFlush() {
        val completions: List<Runnable>
        synchronized(lock) {
            scheduledFlush = null
            if (flushRunning) {
                flushRequested = true
                return
            }
            flushRunning = true
            flushRequested = false
            completions = pendingCompletions.toList()
            pendingCompletions.clear()
        }

        val retryDelayMs = drainAndSend()

        synchronized(lock) {
            flushRunning = false
            val requestImmediately = flushRequested || pendingCompletions.isNotEmpty()
            flushRequested = false
            when {
                requestImmediately -> requestFlushLocked(0)
                retryDelayMs != null -> scheduleFlushLocked(retryDelayMs)
                buffer.isNotEmpty() -> requestFlushLocked(0)
            }
        }
        completions.forEach { completion ->
            try {
                completion.run()
            } catch (_: Exception) {
                // Telemetry completion callbacks must not terminate the transport worker.
            }
        }
    }

    private fun drainAndSend(): Long? {
        val batch: List<QueuedEvent>
        synchronized(lock) {
            if (buffer.isEmpty()) return null
            val count = minOf(buffer.size, config.batchSize, MAX_BATCH_SIZE)
            batch = List(count) { buffer.removeFirst() }
            batch.forEach { it.attempts += 1 }
        }

        val events = batch.map(QueuedEvent::event)
        val body = AbtoJson.encode(mapOf("batch" to events)).toByteArray(Charsets.UTF_8)
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
                    val eventIds = events.mapNotNull { it["event_id"] as? String }
                    val retryIds = retryEventIds(responseBody, eventIds)
                    if (retryIds == null) {
                        batch
                    } else {
                        batch.filter {
                            it.event["event_id"] !is String || it.event["event_id"] in retryIds
                        }
                    }
                }
            } finally {
                connection.disconnect()
            }
        } catch (_: Exception) {
            batch
        }

        val nowMs = System.currentTimeMillis()
        val eligibleRetryBatch = retryBatch.filter {
            retryEligible(it.attempts, it.firstQueuedAtMs, nowMs)
        }
        if (eligibleRetryBatch.isNotEmpty()) {
            synchronized(lock) {
                // Cap the buffer so a dead endpoint cannot grow memory without bound.
                eligibleRetryBatch.asReversed().forEach { buffer.addFirst(it) }
                while (buffer.size > MAX_BUFFER) buffer.removeLast()
            }
            return retryDelayMs(eligibleRetryBatch)
        }
        return null
    }

    private fun requestFlushLocked(delayMs: Long) {
        if (flushRunning) {
            flushRequested = true
            return
        }
        if (delayMs == 0L && scheduledFlush != null) {
            scheduledFlush?.cancel(false)
            scheduledFlush = null
        }
        scheduleFlushLocked(delayMs)
    }

    private fun scheduleFlushLocked(delayMs: Long) {
        if (scheduledFlush != null) return
        scheduledFlush = executor.schedule({ runScheduledFlush() }, delayMs, TimeUnit.MILLISECONDS)
    }

    private fun retryDelayMs(batch: List<QueuedEvent>): Long {
        val attempt = batch.maxOfOrNull(QueuedEvent::attempts) ?: 1
        val baseMs = maxOf(1, config.flushIntervalMs)
        val exponentialMs = minOf(MAX_RETRY_DELAY_MS, baseMs * (1L shl (attempt - 1)))
        val jitterBound = maxOf(1, exponentialMs / 2)
        return exponentialMs + ThreadLocalRandom.current().nextLong(jitterBound)
    }

    private companion object {
        const val MAX_BUFFER = 1000
        const val MAX_BATCH_SIZE = 100
        const val MAX_ATTEMPTS = 3
        const val MAX_EVENT_AGE_MS = 5 * 60 * 1000L
        const val MAX_RETRY_DELAY_MS = 60 * 1000L
        val ACK_RESULTS = setOf("ok", "warning", "drop")
        val RESULT_PATTERN = Regex(""""result"\s*:\s*"([^"]+)"""")

        fun isTransientStatus(status: Int): Boolean = status == 408 || status == 429 || status >= 500

        fun retryEligible(attempts: Int, firstQueuedAtMs: Long, nowMs: Long): Boolean =
            attempts < MAX_ATTEMPTS && nowMs - firstQueuedAtMs < MAX_EVENT_AGE_MS

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
