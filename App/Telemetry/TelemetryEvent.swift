import Foundation

public enum TelemetryPrivacyLevel: String, CaseIterable, Sendable {
    case behavioral = "Behavioral"
    case functional = "Functional"
    case technical = "Technical"
}

public enum TelemetryPersonalization: String, CaseIterable, Sendable {
    case userPreferred = "UserPreferred"
}

public enum TelemetryEventName: String, CaseIterable, Sendable {
    case applicationInstall = "Application_Install"
    case authenticationProvider = "AuthenticationProvider"
    case autoUpdate = "AutoUpdate"
    case checkGFN = "CheckGFN"
    case exception = "Exception"
    case gameQuitEvent = "Game_Quit_Event"
    case gfnSession = "GFNSession"
    case httpFailure = "HTTPFailure"
    case httpSuccess = "HTTPSuccess"
    case launchProcess = "LaunchProcess"
    case loginStart = "LoginStart"
    case networkTest = "NetworkTest"
    case networkTestHTTP = "NetworkTest_Http_Event"
    case networkTestException = "NetworkTest_Exception_Event"
    case pageLoadPerformanceMetrics = "PageLoadPerformanceMetrics"
    case popUpDialogClosed = "PopUpDialogClosed"
    case popUpDialogShown = "PopUpDialogShown"
    case routingStatus = "RoutingStatus"
    case settingSnapshot = "SettingSnapshot"
    case streamingProfile = "StreamingProfile"
    case streamingQualityChanged = "StreamingQualityChangedEvent"
    case systemInfo = "SystemInfo"
    case uiAction = "UIAction"
    case userSession = "UserSession"
    case udsDialogShown = "UDSDialogShown"
    case udsEndOfSessionReport = "UdsEndOfSessionReport"
    case udsSuggestionFeedback = "UDSSuggestionFeedback"
    case gameLaunchEvent = "Game_Launch_Event"
    case gameLaunchMetrics = "Game_Launch_Metrics"

    public var privacyLevel: TelemetryPrivacyLevel {
        switch self {
        case .applicationInstall, .networkTest, .userSession:
            .behavioral
        case .authenticationProvider, .autoUpdate, .checkGFN, .exception, .gameQuitEvent, .gfnSession, .httpFailure, .httpSuccess, .launchProcess, .networkTestHTTP, .pageLoadPerformanceMetrics, .popUpDialogShown, .routingStatus, .streamingQualityChanged, .systemInfo, .uiAction, .udsDialogShown, .udsEndOfSessionReport, .udsSuggestionFeedback, .gameLaunchMetrics:
            .functional
        case .gameLaunchEvent, .loginStart, .networkTestException, .popUpDialogClosed, .settingSnapshot, .streamingProfile:
            .technical
        }
    }

    public var personalization: TelemetryPersonalization {
        .userPreferred
    }
}

public struct TelemetryCommonData: Equatable, Sendable {
    public let appId: String
    public let clientVersion: String
    public let deviceId: String
    public let locale: String
    public let sessionId: String

    public init(appId: String = "pixelnow", clientVersion: String = "", deviceId: String = "", locale: String = "", sessionId: String = "") {
        self.appId = appId
        self.clientVersion = clientVersion
        self.deviceId = deviceId
        self.locale = locale
        self.sessionId = sessionId
    }

    public var dictionary: [String: String] {
        [
            "appId": appId,
            "clientVersion": clientVersion,
            "deviceId": deviceId,
            "locale": locale,
            "sessionId": sessionId,
        ].filter { !$0.value.isEmpty }
    }
}

public struct TelemetryEvent: Equatable, Sendable {
    public let name: TelemetryEventName
    public let timestamp: String
    public let parameters: [String: String]
    public let privacyLevel: TelemetryPrivacyLevel
    public let personalization: TelemetryPersonalization

    public init(name: TelemetryEventName, timestamp: String = TelemetryEvent.currentTimestamp(), parameters: [String: String] = [:], privacyLevel: TelemetryPrivacyLevel? = nil, personalization: TelemetryPersonalization? = nil) {
        self.name = name
        self.timestamp = timestamp
        self.parameters = parameters
        self.privacyLevel = privacyLevel ?? name.privacyLevel
        self.personalization = personalization ?? name.personalization
    }

    public var dictionary: [String: Any] {
        [
            "name": name.rawValue,
            "timestamp": timestamp,
            "parameters": parameters,
            "privacyLevel": privacyLevel.rawValue,
            "personalization": personalization.rawValue,
        ]
    }

    public static func currentTimestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }
}

public enum TelemetryRecorder {
    @discardableResult
    public static func record(_ event: TelemetryEvent, commonData: TelemetryCommonData = TelemetryCommonData()) -> Bool {
        guard Sentry.isTelemetryEnabled() else { return false }
        let attributes = sentryAttributes(event: event, commonData: commonData)
        _ = Sentry.recordCounterMetric(key: "pixelnow.telemetry.events.count", value: 1, attributes: attributes)
        Sentry.logInfoMessage(Sentry.formattedLogMessage(level: "info", area: "Telemetry", message: logMessage(event: event, commonData: commonData)))
        return true
    }

    static func sentryAttributes(event: TelemetryEvent, commonData: TelemetryCommonData) -> [String: Any] {
        var attributes: [String: Any] = [
            "pixelnow.event": event.name.rawValue,
            "pixelnow.privacy_level": event.privacyLevel.rawValue,
            "pixelnow.personalization": event.personalization.rawValue,
        ]
        for (key, value) in commonData.dictionary {
            attributes["pixelnow.common.\(key)"] = sanitizedTelemetryValue(key: key, value: value)
        }
        for (key, value) in event.parameters where !key.isEmpty {
            attributes["pixelnow.parameter.\(Sentry.sanitizedLogMessage(key))"] = sanitizedTelemetryValue(key: key, value: value)
        }
        return attributes.filter { !$0.key.isEmpty }
    }

    static func logMessage(event: TelemetryEvent, commonData: TelemetryCommonData) -> String {
        let parameterText = sortedPairs(event.parameters)
        let commonText = sortedPairs(commonData.dictionary)
        return "Event name=\(event.name.rawValue) privacy=\(event.privacyLevel.rawValue) personalization=\(event.personalization.rawValue) timestamp=\(event.timestamp) parameters=\(parameterText) common=\(commonText)"
    }

    private static func sortedPairs(_ dictionary: [String: String]) -> String {
        let pairs = dictionary.keys.sorted().map { key in
            "\(Sentry.sanitizedLogMessage(key))=\(sanitizedTelemetryValue(key: key, value: dictionary[key] ?? ""))"
        }
        return pairs.isEmpty ? "[]" : "[\(pairs.joined(separator: ","))]"
    }

    private static func sanitizedTelemetryValue(key: String, value: String) -> String {
        if key.localizedCaseInsensitiveContains("version") { return value }
        return Sentry.sanitizedLogMessage(value)
    }
}
