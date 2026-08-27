import Foundation

enum WebRTCStreamSidebarFeature: String, CaseIterable, Hashable, Sendable {
    case microphone
    case recording
    case antiAFK
    case floatingStats
    case networkHealth
    case sessionLimit
    case remoteCoOp
    case videoEnhancement
}

struct WebRTCStreamSidebarCapabilities: Equatable, Sendable {
    let availableFeatures: Set<WebRTCStreamSidebarFeature>

    static let standard = WebRTCStreamSidebarCapabilities(availableFeatures: Set(WebRTCStreamSidebarFeature.allCases))

    var visibleFeatures: [WebRTCStreamSidebarFeature] {
        WebRTCStreamSidebarFeature.allCases
    }

    func supports(_ feature: WebRTCStreamSidebarFeature) -> Bool {
        availableFeatures.contains(feature)
    }
}
