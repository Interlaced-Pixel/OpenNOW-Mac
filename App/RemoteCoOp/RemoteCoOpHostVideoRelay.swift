import Foundation
import Foundation
@preconcurrency import WebRTC

public protocol RemoteCoOpHostVideoSink: AnyObject, Sendable {
    var participantID: UUID { get }
    func renderVideoFrame(_ frame: RTCVideoFrame)
}

public final class RemoteCoOpHostVideoRelay: @unchecked Sendable {
    private let lock = NSLock()
    private var sinks: [UUID: any RemoteCoOpHostVideoSink] = [:]

    public init() {}

    public func upsert(_ sink: any RemoteCoOpHostVideoSink) {
        lock.withLock { sinks[sink.participantID] = sink }
    }

    public func remove(participantID: UUID) {
        lock.withLock { sinks[participantID] = nil }
    }

    public func removeAll() {
        lock.withLock { sinks.removeAll() }
    }

    public func activeSinkCount() -> Int {
        lock.withLock { sinks.count }
    }

    public func renderVideoFrame(_ frame: RTCVideoFrame) {
        let currentSinks = lock.withLock { Array(sinks.values) }
        for sink in currentSinks { sink.renderVideoFrame(frame) }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
