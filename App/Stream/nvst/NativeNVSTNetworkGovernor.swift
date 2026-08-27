import Foundation

enum NativeNVSTNetworkAdjustment: Equatable, Sendable {
    case maximumBitrateKbps(UInt32)
    case dynamicStreamingMode(NativeNVSTDynamicStreamingMode)
    case l4sEnabled(Bool)
}

/// Bifrost owns native NVST congestion control. This adapter intentionally emits
/// no local adjustments until a verified vendor control contract exists.
struct NativeNVSTNetworkGovernor: Equatable, Sendable {
    init(maximumBitrateKbps _: UInt32, l4sEnabled _: Bool) {}

    mutating func evaluate(_: NativeNVSTPerformanceSnapshot) -> [NativeNVSTNetworkAdjustment] {
        return []
    }
}
