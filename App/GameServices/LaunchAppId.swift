import Foundation

struct ResolvedLaunchAppId: Equatable, Sendable {
    let stringValue: String
    let intValue: Int
}

enum LaunchAppId {
    static func resolve(_ value: String) -> ResolvedLaunchAppId? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let intValue = Int(trimmed), intValue > 0 else { return nil }
        return ResolvedLaunchAppId(stringValue: trimmed, intValue: intValue)
    }
}
