import Foundation

enum AccountStorageKeys {
    static let namespace = "PixelNOW.Account"
    static let activeUserIdDefaultsKey = "PixelNOW_ActiveUserId"

    enum Name: String, Sendable {
        case previousGameSession = "PreviousGameSession"
        case activeSessionId = "ActiveSessionId"
        case sessionLimitStartedAt = "SessionLimitStartedAtEpochSeconds"
        case regionUrl = "RegionUrl"
        case cachedRegions = "CachedRegions"
        case cloudVariablesJSON = "CloudVariablesJSON"
        case cloudVariablesTimestamp = "CloudVariablesTimestamp"
        case playtimeStatistics = "PlaytimeStatistics"
    }

    static func requireUserId(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func canonicalUserId(accountUserId: String, sessionUserId: String) -> String? {
        requireUserId(sessionUserId) ?? requireUserId(accountUserId)
    }

    static func key(_ name: Name, userId: String) -> String? {
        key(name.rawValue, userId: userId)
    }

    static func key(_ name: String, userId: String) -> String? {
        guard let userId = requireUserId(userId) else { return nil }
        return "\(namespace).\(userId).\(name)"
    }

    static func authUserDefaults() -> UserDefaults {
        let environment = ProcessInfo.processInfo.environment
        if let suiteName = environment["PIXELNOW_AUTH_USER_DEFAULTS_SUITE"],
           !suiteName.isEmpty {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }

    static func activeUserId() -> String? {
        let defaults = authUserDefaults()
        if let activeUserId = requireUserId(defaults.string(forKey: activeUserIdDefaultsKey) ?? "") {
            return activeUserId
        }
        return nil
    }

    static func persistedActiveSessionIdKey(userId: String? = nil) -> String {
        let resolved = requireUserId(userId ?? activeUserId() ?? "")
        if let resolved, let key = key(.activeSessionId, userId: resolved) {
            return key
        }
        return "\(namespace).\(Name.activeSessionId.rawValue)"
    }

    static func sessionLimitStartedAtKey(userId: String? = nil) -> String {
        let resolved = requireUserId(userId ?? activeUserId() ?? "")
        if let resolved, let key = key(.sessionLimitStartedAt, userId: resolved) {
            return key
        }
        return "\(namespace).\(Name.sessionLimitStartedAt.rawValue)"
    }
}
