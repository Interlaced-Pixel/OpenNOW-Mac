import Foundation

import Foundation

final class JarvisSentryTelemetry: JarvisTelemetry, @unchecked Sendable {
    static let shared = JarvisSentryTelemetry()

    private init() {}

    func startSpan(name: String, operation: Jarvis.Operation?, attributes: [String: String]) -> JarvisTelemetrySpan {
        let transaction = Sentry.startTransaction(name: name.isEmpty ? "Jarvis auth" : name, operation: "jarvis.auth", makeCurrent: false)
        let span = JarvisSentryTelemetrySpan(transaction: transaction)
        if let operation { span.setAttribute("jarvis.operation", value: operation.rawValue) }
        for (key, value) in attributes { span.setAttribute(key, value: value) }
        return span
    }

    func recordBreadcrumb(_ message: String, attributes: [String: String]) {
        let suffix = attributes.isEmpty ? "" : " " + attributes.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        Sentry.logInfoMessage(Sentry.formattedLogMessage(level: "info", area: "Jarvis", message: "\(message)\(suffix)"))
    }

    func recordCounter(name: String, attributes: [String: String]) {
        _ = Sentry.recordCounterMetric(key: name.isEmpty ? "jarvis.auth.count" : name, value: 1, attributes: attributes)
    }

    func recordError(_ error: Error, operation: Jarvis.Operation?, attributes: [String: String]) {
        var parts = attributes
        if let operation { parts["jarvis.operation"] = operation.rawValue }
        let suffix = parts.isEmpty ? "" : " " + parts.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        let level = Self.logLevel(error: error, attributes: parts)
        let message = Sentry.formattedLogMessage(level: level, area: "Jarvis", message: "\(error.localizedDescription)\(suffix)")
        if level == "error" {
            Sentry.logErrorMessage(message)
        } else {
            Sentry.logWarningMessage(message)
        }
    }

    private static func logLevel(error: Error, attributes: [String: String]) -> String {
        let description = error.localizedDescription.lowercased()
        if attributes["phase"] == "callback" || description.contains("idp callback") { return "warning" }
        return "error"
    }
}

private final class JarvisSentryTelemetrySpan: JarvisTelemetrySpan, @unchecked Sendable {
    private let transaction: SentryTransaction?

    init(transaction: SentryTransaction?) {
        self.transaction = transaction
    }

    func setAttribute(_ key: String, value: String) {
        transaction?.setTag(key, value: value)
        transaction?.setData(key, value: value)
    }

    func finish(success: Bool) {
        transaction?.setStatus(success)
        transaction?.finish()
    }
}
