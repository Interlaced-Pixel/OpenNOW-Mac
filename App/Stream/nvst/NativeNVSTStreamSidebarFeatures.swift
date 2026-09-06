import Foundation

enum NativeNVSTStreamSidebarFeature: String, CaseIterable, Hashable, Sendable {
    case microphone
    case recording
    case antiAFK
    case floatingStats
    case networkHealth
    case sessionLimit
    case remoteCoOp
    case videoEnhancement
}

struct NativeNVSTStreamSidebarCapabilities: Equatable, Sendable {
    let availableFeatures: Set<NativeNVSTStreamSidebarFeature>

    static let standard = NativeNVSTStreamSidebarCapabilities(availableFeatures: [
        .microphone,
        .recording,
        .antiAFK,
        .floatingStats,
        .networkHealth,
        .sessionLimit,
    ])

    var visibleFeatures: [NativeNVSTStreamSidebarFeature] {
        NativeNVSTStreamSidebarFeature.allCases
    }

    func supports(_ feature: NativeNVSTStreamSidebarFeature) -> Bool {
        availableFeatures.contains(feature)
    }
}
