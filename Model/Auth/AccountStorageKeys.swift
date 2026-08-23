import Foundation

enum AccountStorageKeys {
    static let namespace = "OpenNOW.Account"
    static let activeUserIdDefaultsKey = "OPN_ActiveUserId"

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

    enum Legacy {
        static let previousGameSession = "OpenNOW.Catalog.PreviousGameSession"
        static let activeSessionId = "OpenNOW.Stream.ActiveSessionId"
        static let sessionLimitStartedAt = "OpenNOW.Stream.SessionLimitStartedAtEpochSeconds"
        static let regionUrl = "OpenNOW.Stream.RegionUrl"
        static let cachedRegions = "OpenNOW.Stream.CachedRegions"
        static let cloudVariablesJSON = "OpenNOW.Stream.CloudVariablesJSON"
        static let cloudVariablesTimestamp = "OpenNOW.Stream.CloudVariablesTimestamp"

        static func playtimeStatistics(accountIdentifier: String) -> String {
            "OpenNOW.Catalog.PlaytimeStatistics.\(accountIdentifier)"
        }
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
        if let suiteName = ProcessInfo.processInfo.environment["OPN_AUTH_USER_DEFAULTS_SUITE"], !suiteName.isEmpty {
            return UserDefaults(suiteName: suiteName) ?? .standard
        }
        return .standard
    }

    static func activeUserId() -> String? {
        requireUserId(authUserDefaults().string(forKey: activeUserIdDefaultsKey) ?? "")
    }

    static func persistedActiveSessionIdKey(userId: String? = nil) -> String {
        let resolved = requireUserId(userId ?? activeUserId() ?? "")
        if let resolved, let key = key(.activeSessionId, userId: resolved) {
            migrateObject(fromLegacyKey: Legacy.activeSessionId, toAccountKey: key)
            return key
        }
        return Legacy.activeSessionId
    }

    static func sessionLimitStartedAtKey(userId: String? = nil) -> String {
        let resolved = requireUserId(userId ?? activeUserId() ?? "")
        if let resolved, let key = key(.sessionLimitStartedAt, userId: resolved) {
            migrateObject(fromLegacyKey: Legacy.sessionLimitStartedAt, toAccountKey: key)
            return key
        }
        return Legacy.sessionLimitStartedAt
    }

    static func migrateObject(
        fromLegacyKey legacyKey: String,
        toAccountKey accountKey: String,
        defaults: UserDefaults = .standard
    ) {
        guard defaults.object(forKey: accountKey) == nil else { return }
        guard let value = defaults.object(forKey: legacyKey) else { return }
        defaults.set(value, forKey: accountKey)
        defaults.removeObject(forKey: legacyKey)
        defaults.synchronize()
    }
}
