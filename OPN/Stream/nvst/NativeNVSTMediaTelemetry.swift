import Foundation

public enum NativeNVSTMediaTelemetryLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

public enum NativeNVSTMediaTelemetryMetricKind: String, Sendable {
    case counter
    case gauge
    case distribution
}

public struct NativeNVSTMediaTelemetryEvent: Sendable {
    public let name: String
    public let level: NativeNVSTMediaTelemetryLevel
    public let message: String
    public let attributes: [String: String]
    public let timestamp: Date

    public init(name: String,
                level: NativeNVSTMediaTelemetryLevel,
                message: String,
                attributes: [String: String] = [:],
                timestamp: Date = Date()) {
        self.name = name
        self.level = level
        self.message = message
        self.attributes = attributes
        self.timestamp = timestamp
    }
}

public struct NativeNVSTMediaTelemetryMetric: Sendable {
    public let key: String
    public let kind: NativeNVSTMediaTelemetryMetricKind
    public let value: Double
    public let unit: String?
    public let attributes: [String: String]

    public init(key: String,
                kind: NativeNVSTMediaTelemetryMetricKind,
                value: Double,
                unit: String? = nil,
                attributes: [String: String] = [:]) {
        self.key = key
        self.kind = kind
        self.value = value
        self.unit = unit
        self.attributes = attributes
    }
}

public protocol NativeNVSTMediaTelemetrySink: Sendable {
    func capture(_ event: NativeNVSTMediaTelemetryEvent)
    func record(_ metric: NativeNVSTMediaTelemetryMetric)
}

public extension NativeNVSTMediaTelemetrySink {
    func record(_ metric: NativeNVSTMediaTelemetryMetric) {}
}

public enum NativeNVSTMediaTelemetry {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var sink: (any NativeNVSTMediaTelemetrySink)?

    public static func configure(sink: (any NativeNVSTMediaTelemetrySink)?) {
        lock.withLock {
            self.sink = sink
        }
    }

    public static func capture(_ name: String,
                               level: NativeNVSTMediaTelemetryLevel,
                               message: String,
                               attributes: [String: String] = [:]) {
        let event = NativeNVSTMediaTelemetryEvent(name: name, level: level, message: message, attributes: attributes)
        if let sink = currentSink() {
            sink.capture(event)
        } else if level != .debug {
            NSLog("%@", "[NativeNVSTMedia][\(level.rawValue)] \(name): \(message)")
        }
    }

    public static func record(_ key: String,
                              kind: NativeNVSTMediaTelemetryMetricKind,
                              value: Double,
                              unit: String? = nil,
                              attributes: [String: String] = [:]) {
        currentSink()?.record(NativeNVSTMediaTelemetryMetric(key: key, kind: kind, value: value, unit: unit, attributes: attributes))
    }

    private static func currentSink() -> (any NativeNVSTMediaTelemetrySink)? {
        lock.withLock { sink }
    }
}
