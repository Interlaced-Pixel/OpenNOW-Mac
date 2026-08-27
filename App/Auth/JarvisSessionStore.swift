
final class PersistedJarvisSessionStore: JarvisSessionStore, @unchecked Sendable {
    static let shared = PersistedJarvisSessionStore()

    private init() {}

    func loadSession() async throws -> JarvisSession {
        AuthService.shared.loadSavedSession()
    }

    func saveSession(_ session: JarvisSession) async throws {
        AuthService.shared.saveSession(session)
    }

    func clearSession() async throws {
        AuthService.shared.clearSession()
    }

    func loadUserInfo() async throws -> JarvisUserInfo {
        let session = AuthService.shared.loadSavedSession()
        guard session.isAuthenticated else { return JarvisUserInfo() }
        return JarvisUserInfo(
            userId: session.userId,
            idpId: session.idpId,
            displayName: session.displayName,
            email: session.email,
            isAuthenticated: true,
            isNetworkCall: false
        )
    }

    func saveUserInfo(_ userInfo: JarvisUserInfo) async throws {
        AuthService.shared.saveUserInfo(userInfo)
    }

    func clearUserInfo() async throws {
        AuthService.shared.clearUserInfo()
    }
}
