import Foundation

struct OpenNOWNativeNVSTMediaTelemetrySink: NativeNVSTMediaTelemetrySink {
    func capture(_ event: NativeNVSTMediaTelemetryEvent) {
        let suffix = event.attributes.isEmpty ? "" : " " + event.attributes.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        let level = Self.sentryLevel(for: event)
        let message = "\(event.name): \(event.message)\(suffix)"
        switch level {
        case .debug:
            OpenNOWLog.debug(.stream, message)
        case .info:
            OpenNOWLog.info(.stream, message)
        case .warning:
            OpenNOWLog.warning(.stream, message)
        case .error:
            OpenNOWLog.error(.stream, message)
        }
    }

    private static func sentryLevel(for event: NativeNVSTMediaTelemetryEvent) -> NativeNVSTMediaTelemetryLevel {
        guard event.level == .error else { return event.level }
        if event.name == "nvst.path.session_provider.error" { return .warning }
        return event.level
    }

    func record(_ metric: NativeNVSTMediaTelemetryMetric) {
        let attributes = metric.attributes as [String: Any]
        switch metric.kind {
        case .counter:
            _ = OPNSentry.recordCounterMetric(key: metric.key, value: Int64(max(0, metric.value.rounded())), attributes: attributes)
        case .gauge:
            _ = OPNSentry.recordGaugeMetric(key: metric.key, value: metric.value, unit: metric.unit, attributes: attributes)
        case .distribution:
            _ = OPNSentry.recordDistributionMetric(key: metric.key, value: metric.value, unit: metric.unit, attributes: attributes)
        }
    }
}
