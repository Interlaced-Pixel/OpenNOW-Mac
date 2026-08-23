import Foundation
import Testing
@testable import OpenNOW

@Suite(.serialized)
struct MultiAccountAuthServiceTests {
    @Test func saveTwoSessionsThenSetActiveReturnsMatchingTokens() throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        let first = AuthTestIsolation.session(userId: "user-a", accessToken: "token-a", email: "a@example.com")
        let second = AuthTestIsolation.session(userId: "user-b", accessToken: "token-b", email: "b@example.com")
        service.saveSession(first)
        service.saveSession(second)

        service.setActiveSessionUserId("user-a")
        let loadedA = service.loadSavedSession(forUserId: "user-a")
        #expect(loadedA.accessToken == "token-a")
        #expect(loadedA.userId == "user-a")
        #expect(service.loadSavedSession().userId == "user-a")

        service.setActiveSessionUserId("user-b")
        let loadedB = service.loadSavedSession(forUserId: "user-b")
        #expect(loadedB.accessToken == "token-b")
        #expect(loadedB.userId == "user-b")
        #expect(service.loadSavedSession().userId == "user-b")
        #expect(service.loadSavedSession(forUserId: "user-a").accessToken == "token-a")
    }

    @Test func removeSavedSessionLeavesTheOtherAccountAndMovesActivePointer() throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        service.saveSession(AuthTestIsolation.session(userId: "user-a", accessToken: "token-a", email: "a@example.com"))
        service.saveSession(AuthTestIsolation.session(userId: "user-b", accessToken: "token-b", email: "b@example.com"))
        service.setActiveSessionUserId("user-a")

        service.removeSavedSession(userId: "user-a")

        #expect(service.loadSavedSession(forUserId: "user-a").isAuthenticated == false)
        #expect(service.loadSavedSession(forUserId: "user-b").accessToken == "token-b")
        #expect(service.loadSavedSession().userId == "user-b")
        #expect(service.loadSavedSessions().map(\.userId).sorted() == ["user-b"])
    }

    @Test func clearSessionRemovesOnlyTheActiveAccount() throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        service.saveSession(AuthTestIsolation.session(userId: "user-a", accessToken: "token-a", email: "a@example.com"))
        service.saveSession(AuthTestIsolation.session(userId: "user-b", accessToken: "token-b", email: "b@example.com"))
        service.setActiveSessionUserId("user-a")

        service.clearSession()

        #expect(service.loadSavedSession(forUserId: "user-a").isAuthenticated == false)
        #expect(service.loadSavedSession(forUserId: "user-b").accessToken == "token-b")
        #expect(service.loadSavedSessions().map(\.userId) == ["user-b"])
    }

    @Test func identityIsUserIdOnlyAndEmptyUserIdIsRejected() throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        var missingUserId = AuthTestIsolation.session(userId: "", accessToken: "token-missing", email: "missing@example.com")
        missingUserId.userId = ""
        service.saveSession(missingUserId)
        #expect(service.loadSavedSessions().isEmpty)

        let named = AuthTestIsolation.session(userId: "user-named", accessToken: "token-named", email: "named@example.com", displayName: "Named")
        service.saveSession(named)
        service.setActiveSessionUserId("named@example.com")
        #expect(service.loadSavedSession().userId == "user-named")
        #expect(service.loadSavedSession(forUserId: "named@example.com").isAuthenticated == false)
        #expect(service.loadSavedSession(forUserId: "Named").isAuthenticated == false)
        #expect(service.loadSavedSession(forUserId: "token-named").isAuthenticated == false)
    }
}

@Suite(.serialized)
struct AccountStorageIsolationTests {
    @Test func previousSessionAndActiveSessionIdKeysDoNotLeakAcrossUserIds() throws {
        let firstUser = "user-one"
        let secondUser = "user-two"
        let firstPreviousKey = try #require(AccountStorageKeys.key(.previousGameSession, userId: firstUser))
        let secondPreviousKey = try #require(AccountStorageKeys.key(.previousGameSession, userId: secondUser))
        let firstSessionKey = AccountStorageKeys.persistedActiveSessionIdKey(userId: firstUser)
        let secondSessionKey = AccountStorageKeys.persistedActiveSessionIdKey(userId: secondUser)
        let defaults = UserDefaults.standard
        let previousKeys = [firstPreviousKey, secondPreviousKey, firstSessionKey, secondSessionKey, AccountStorageKeys.Legacy.previousGameSession, AccountStorageKeys.Legacy.activeSessionId]
        let preserved = Dictionary(uniqueKeysWithValues: previousKeys.map { ($0, defaults.object(forKey: $0)) })
        defer {
            for (key, value) in preserved {
                if let value {
                    defaults.set(value, forKey: key)
                } else {
                    defaults.removeObject(forKey: key)
                }
            }
            defaults.synchronize()
        }

        previousKeys.forEach { defaults.removeObject(forKey: $0) }
        defaults.set("first-session".data(using: .utf8), forKey: firstPreviousKey)
        defaults.set("resume-a", forKey: firstSessionKey)

        #expect(defaults.data(forKey: secondPreviousKey) == nil)
        #expect(defaults.string(forKey: secondSessionKey) == nil)
        #expect(AccountStorageKeys.key(.previousGameSession, userId: firstUser) != AccountStorageKeys.key(.previousGameSession, userId: secondUser))
        #expect(firstSessionKey == "OpenNOW.Account.user-one.ActiveSessionId")
        #expect(secondSessionKey == "OpenNOW.Account.user-two.ActiveSessionId")
        #expect(defaults.string(forKey: firstSessionKey) == "resume-a")
    }
}
