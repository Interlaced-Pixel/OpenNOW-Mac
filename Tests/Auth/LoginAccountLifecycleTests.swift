import Foundation
import SwiftData
import Testing
@testable import OpenNOW

@Suite(.serialized)
@MainActor
struct LoginAccountLifecycleTests {
    @Test func forgetRemovesSwiftDataAndPlistTogether() async throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        service.saveSession(AuthTestIsolation.session(userId: "user-a", accessToken: "token-a", email: "a@example.com"))
        service.saveSession(AuthTestIsolation.session(userId: "user-b", accessToken: "token-b", email: "b@example.com"))

        let environment = try makeLoginEnvironment(
            accounts: [
                makeAccount(userId: "user-a", email: "a@example.com", displayName: "Alpha", isActive: true),
                makeAccount(userId: "user-b", email: "b@example.com", displayName: "Bravo", isActive: false),
            ]
        )
        let forgotten = try #require(environment.viewModel.rememberedAccounts.first { $0.userId == "user-a" })
        environment.viewModel.forgetAccount(forgotten)
        try await waitUntil {
            environment.viewModel.rememberedAccounts.contains { $0.userId == "user-a" } == false
        }

        #expect(environment.viewModel.rememberedAccounts.map(\.userId).sorted() == ["user-b"])
        #expect(service.loadSavedSession(forUserId: "user-a").isAuthenticated == false)
        #expect(service.loadSavedSession(forUserId: "user-b").accessToken == "token-b")
    }

    @Test func signOutLeavesSecondRememberedAccountRestorableFromLoginWall() async throws {
        let isolation = try AuthTestIsolation.begin()
        defer { isolation.end() }
        let service = OPNAuthService.shared
        service.saveSession(AuthTestIsolation.session(userId: "user-a", accessToken: "token-a", email: "a@example.com"))
        service.saveSession(AuthTestIsolation.session(userId: "user-b", accessToken: "token-b", email: "b@example.com"))
        service.setActiveSessionUserId("user-a")

        let environment = try makeLoginEnvironment(
            accounts: [
                makeAccount(userId: "user-a", email: "a@example.com", displayName: "Alpha", isActive: true),
                makeAccount(userId: "user-b", email: "b@example.com", displayName: "Bravo", isActive: false),
            ]
        )
        #expect(environment.viewModel.activeAccount?.userId == "user-a")
        environment.viewModel.signOut()
        try await waitUntil { environment.viewModel.activeSession == nil }

        let remaining = environment.viewModel.rememberedAccounts
        #expect(remaining.contains { $0.userId == "user-b" })
        #expect(environment.viewModel.activeSession == nil)
        #expect(service.loadSavedSession(forUserId: "user-b").accessToken == "token-b")
        let bravo = try #require(remaining.first { $0.userId == "user-b" })
        #expect(environment.viewModel.canRestoreAccount(bravo))
    }

    private struct LoginEnvironment {
        let container: ModelContainer
        let context: ModelContext
        let viewModel: LoginViewModel
    }

    private func makeLoginEnvironment(accounts: [LoginAccount]) throws -> LoginEnvironment {
        let schema = Schema([LoginAccount.self, LoginSession.self, LoginDeviceRegistration.self])
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        let context = ModelContext(container)
        var sessions: [LoginSession] = []
        for account in accounts {
            context.insert(account)
            let session = LoginSession(
                accountEmail: account.email,
                authMethod: Jarvis.Operation.getSessionToken.rawValue,
                accessToken: "token-\(account.userId)",
                clientToken: "client-\(account.userId)",
                idToken: "id-\(account.userId)",
                refreshToken: "refresh-\(account.userId)",
                userId: account.userId,
                idpId: Jarvis.defaultIdpId,
                deviceId: "device",
                expiresAt: Date().addingTimeInterval(3_600),
                clientTokenExpiresAt: Date().addingTimeInterval(3_600),
                isActive: account.isActive,
                canContinueOffline: true
            )
            context.insert(session)
            sessions.append(session)
        }
        let device = LoginDeviceRegistration()
        context.insert(device)
        try context.save()

        let viewModel = LoginViewModel()
        viewModel.update(modelContext: context, accounts: accounts, sessions: sessions, devices: [device])
        viewModel.bootstrap()
        return LoginEnvironment(container: container, context: context, viewModel: viewModel)
    }

    private func makeAccount(userId: String, email: String, displayName: String, isActive: Bool) -> LoginAccount {
        LoginAccount(
            email: email,
            displayName: displayName,
            providerIdpId: Jarvis.defaultIdpId,
            providerName: "NVIDIA",
            userId: userId,
            lastLoginAt: Date(),
            rememberSession: true,
            isActive: isActive
        )
    }

    private func waitUntil(timeoutNanoseconds: UInt64 = 2_000_000_000, _ condition: () -> Bool) async throws {
        let deadline = DispatchTime.now() + .nanoseconds(Int(timeoutNanoseconds))
        while DispatchTime.now() < deadline {
            if condition() { return }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(condition())
    }
}
