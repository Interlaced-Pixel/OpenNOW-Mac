import Foundation

public enum SelectedStreamTransport: String, Equatable, Sendable {
    case webRTC = "webrtc"
    case nativeNVST = "nvst"
}

public enum StreamTransportSelector {
    public static func selectedTransport(forGame applicationID: String,
                                         capabilities: StreamDeviceCapabilities = StreamPreferences.loadDeviceCapabilities()) -> SelectedStreamTransport {
        let profile = StreamPreferences.launchProfile(forGame: applicationID, capabilities: capabilities)
        let requestsNativeNVST = profile.transportMode.value.caseInsensitiveCompare(SelectedStreamTransport.nativeNVST.rawValue) == .orderedSame
        guard requestsNativeNVST else { return .webRTC }
        if case .success = NVSTNativeRuntime.availability() {
            return .nativeNVST
        }
        StreamPreferences.saveNVSTTransportEnabled(false)
        return .webRTC
    }
}
