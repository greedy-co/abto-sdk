import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// 배치 전송 — 큐에 쌓고 batchSize/타이머로 flush 한다.
/// 텔레메트리 실패가 호스트 앱을 막지 않도록 절대 throw 하지 않는다 (브라우저 SDK 와 동일 계약).
// Mutable state is confined to `queue`; immutable event payloads cross the
// queue boundary as Data rather than `[String: Any]`.
final class AbtoTransport: @unchecked Sendable {
    private let config: AbtoConfig
    private let queue = DispatchQueue(label: "abto.sdk.transport")
    private var buffer: [Data] = []
    private var timer: DispatchSourceTimer?
    private let session: URLSession
    private static let maxBuffer = 1000

    init(config: AbtoConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func enqueue(_ event: [String: Any]) {
        guard let encodedEvent = try? JSONSerialization.data(withJSONObject: event) else {
            return
        }
        queue.async {
            self.buffer.append(encodedEvent)
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

    private func armTimerLocked() {
        guard timer == nil else { return }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + config.flushInterval)
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
        let batch = buffer
        buffer = []

        guard let events = try? batch.map({ try JSONSerialization.jsonObject(with: $0) }),
              let body = try? JSONSerialization.data(withJSONObject: ["batch": events]) else {
            completion?()
            return
        }
        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(config.projectKey)", forHTTPHeaderField: "authorization")
        request.httpBody = body

        let task = session.dataTask(with: request) { [weak self] _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            if error != nil || status >= 400 {
                self?.requeue(batch)
            }
            completion?()
        }
        task.resume()
    }

    private func requeue(_ batch: [Data]) {
        queue.async {
            // 죽은 endpoint 가 메모리를 무한히 키우지 않게 버퍼를 제한한다.
            self.buffer = Array((batch + self.buffer).prefix(Self.maxBuffer))
        }
    }
}
