import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

package func abtoRetryEventIDs(responseData: Data, eventIDs: [String]) -> Set<String>? {
    guard let decoded = try? JSONSerialization.jsonObject(with: responseData),
          let root = decoded as? [String: Any],
          let results = root["results"] as? [String: Any] else {
        return nil
    }
    let acknowledged = Set(["ok", "warning", "drop"])
    return Set(eventIDs.filter { eventID in
        guard let eventResult = results[eventID] as? [String: Any],
              let result = eventResult["result"] as? String else {
            return true
        }
        return !acknowledged.contains(result)
    })
}

package func abtoRetryEligible(
    attempts: Int,
    firstQueuedAt: Date,
    now: Date = Date()
) -> Bool {
    attempts < abtoMaxAttempts && now.timeIntervalSince(firstQueuedAt) < abtoMaxEventAge
}

/// Batch transport that queues events and flushes on `batchSize` or a timer.
/// Never throws, so telemetry failures cannot block the host app, matching the Browser SDK contract.
// Mutable state is confined to `queue`; immutable event payloads cross the
// queue boundary as Data rather than `[String: Any]`.
final class AbtoTransport: @unchecked Sendable {
    private let config: AbtoConfig
    private let queue = DispatchQueue(label: "abto.sdk.transport")
    private struct QueuedEvent: Sendable {
        let data: Data
        let firstQueuedAt: Date
        var attempts: Int
    }

    private var buffer: [QueuedEvent] = []
    private var timer: DispatchSourceTimer?
    private let session: URLSession

    init(config: AbtoConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func enqueue(_ event: [String: Any]) {
        guard let encodedEvent = try? JSONSerialization.data(withJSONObject: event) else {
            return
        }
        queue.async {
            self.buffer.append(QueuedEvent(data: encodedEvent, firstQueuedAt: Date(), attempts: 0))
            // Cap at production time so a dead endpoint cannot grow memory without bound.
            // On overflow the oldest events go first: recent ones are more useful.
            if self.buffer.count > abtoMaxBufferedEvents {
                self.buffer.removeFirst(self.buffer.count - abtoMaxBufferedEvents)
            }
            if self.buffer.count >= self.config.batchSize {
                self.flushLocked()
            } else {
                self.armTimerLocked()
            }
        }
    }

    func flush(completion: (@Sendable () -> Void)? = nil) {
        queue.async {
            self.flushLocked(completion: completion)
        }
    }

    private func armTimerLocked(delay: TimeInterval? = nil) {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + (delay ?? config.flushInterval))
        t.setEventHandler { [weak self] in
            self?.timer = nil
            self?.flushLocked()
        }
        t.resume()
        timer = t
    }

    private func flushLocked(completion: (@Sendable () -> Void)? = nil) {
        timer?.cancel()
        timer = nil
        guard !buffer.isEmpty else {
            completion?()
            return
        }
        let count = min(buffer.count, config.batchSize, abtoMaxBatchSize)
        var attemptedBatch = Array(buffer.prefix(count))
        for index in attemptedBatch.indices {
            attemptedBatch[index].attempts += 1
        }
        let batch = attemptedBatch
        buffer.removeFirst(count)

        guard let events = try? batch.map({ try JSONSerialization.jsonObject(with: $0.data) }),
              let body = try? JSONSerialization.data(withJSONObject: ["batch": events]) else {
            completion?()
            return
        }
        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(config.projectKey)", forHTTPHeaderField: "authorization")
        request.httpBody = body

        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self else {
                completion?()
                return
            }
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let retryBatch: [QueuedEvent]
            if error != nil || status == 408 || status == 429 || status >= 500 {
                retryBatch = batch
            } else if status >= 400 {
                retryBatch = []
            } else {
                let eventIDs = batch.compactMap { queuedEvent -> String? in
                    guard let event = try? JSONSerialization.jsonObject(with: queuedEvent.data) as? [String: Any] else {
                        return nil
                    }
                    return event["event_id"] as? String
                }
                if let data,
                   let retryIDs = abtoRetryEventIDs(responseData: data, eventIDs: eventIDs) {
                    retryBatch = batch.filter { queuedEvent in
                        guard let event = try? JSONSerialization.jsonObject(with: queuedEvent.data) as? [String: Any],
                              let eventID = event["event_id"] as? String else {
                            return true
                        }
                        return retryIDs.contains(eventID)
                    }
                } else {
                    retryBatch = batch
                }
            }
            self.finish(retryBatch: retryBatch, completion: completion)
        }
        task.resume()
    }

    private func finish(retryBatch: [QueuedEvent], completion: (@Sendable () -> Void)?) {
        queue.async {
            let now = Date()
            let eligible = retryBatch.filter {
                abtoRetryEligible(attempts: $0.attempts, firstQueuedAt: $0.firstQueuedAt, now: now)
            }
            if !eligible.isEmpty {
                // Cap the buffer so a dead endpoint cannot grow memory without bound.
                self.buffer = Array((eligible + self.buffer).prefix(abtoMaxBufferedEvents))
                let attempt = eligible.map(\.attempts).max() ?? 1
                let exponential = min(abtoMaxRetryDelay, self.config.flushInterval * pow(2.0, Double(attempt - 1)))
                let jitter = Double.random(in: 0..<max(0.001, exponential * abtoRetryJitterRatio))
                self.armTimerLocked(delay: exponential + jitter)
            } else if !self.buffer.isEmpty {
                self.flushLocked()
            }
            completion?()
        }
    }

}
