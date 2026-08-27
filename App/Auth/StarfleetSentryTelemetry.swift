
import Foundation

final class StarfleetSentryTelemetry: StarfleetTelemetry, @unchecked Sendable {
    static let shared = StarfleetSentryTelemetry()

    private init() {}

    func startSpan(name: String, attributes: [String: String]) -> StarfleetTelemetrySpan {
        let transaction = Sentry.startTransaction(name: name.isEmpty ? "Starfleet auth" : name, operation: "starfleet.auth", makeCurrent: false)
        let span = StarfleetSentryTelemetrySpan(transaction: transaction)
        for (key, value) in attributes { span.setAttribute(key, value: value) }
        return span
    }

    func recordCounter(name: String, attributes: [String: String]) {
        _ = Sentry.recordCounterMetric(key: name.isEmpty ? "starfleet.auth.count" : name, value: 1, attributes: attributes)
    }

    func recordError(_ error: Error, attributes: [String: String]) {
        let suffix = attributes.isEmpty ? "" : " " + attributes.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        let level = Self.logLevel(error: error)
        let message = Sentry.formattedLogMessage(level: level, area: "Starfleet", message: "\(error.localizedDescription)\(suffix)")
        if level == "error" {
            Sentry.logErrorMessage(message)
        } else {
            Sentry.logWarningMessage(message)
        }
    }

    private static func logLevel(error: Error) -> String {
        guard let error = error as? StarfleetAuthError else { return "error" }
        switch error.category {
        case .authorization, .missingData:
            return "warning"
        case .invalidRequest, .offline, .timeout, .server, .rateLimited, .unavailable, .parsing, .unknown:
            return "error"
        }
    }
}

private final class StarfleetSentryTelemetrySpan: StarfleetTelemetrySpan, @unchecked Sendable {
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
