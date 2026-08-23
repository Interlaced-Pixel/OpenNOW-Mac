import Foundation
import Testing
@testable import OpenNOW

struct AuthTestIsolation {
    let directory: URL
    let suiteName: String

    static func begin() throws -> AuthTestIsolation {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("OpenNOW-Auth-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let suiteName = "io.github.opencloudgaming.OpenNOW.AuthTests.\(UUID().uuidString)"
        setenv("OPN_AUTH_APPLICATION_SUPPORT_DIR", directory.path, 1)
        setenv("OPN_AUTH_USER_DEFAULTS_SUITE", suiteName, 1)
        return AuthTestIsolation(directory: directory, suiteName: suiteName)
    }

    func end() {
        unsetenv("OPN_AUTH_APPLICATION_SUPPORT_DIR")
        unsetenv("OPN_AUTH_USER_DEFAULTS_SUITE")
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }

    static func session(
        userId: String,
        accessToken: String,
        email: String,
        displayName: String? = nil
    ) -> OPNAuthSession {
        var session = OPNAuthSession()
        session.accessToken = accessToken
        session.refreshToken = "refresh-\(userId)"
        session.idToken = "id-\(userId)"
        session.clientToken = "client-\(userId)"
        session.userId = userId
        session.email = email
        session.displayName = displayName ?? email
        session.membershipTier = "Priority"
        session.idpId = Jarvis.defaultIdpId
        session.isAuthenticated = true
        session.expiresAt = Int64(Date().addingTimeInterval(3_600).timeIntervalSince1970)
        session.accessTokenExpiry = Int64(Date().addingTimeInterval(3_600).timeIntervalSince1970 * 1_000)
        return session
    }
}
