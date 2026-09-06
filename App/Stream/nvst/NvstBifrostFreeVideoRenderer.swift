import AppKit
import CoreImage
import CoreMedia
import CoreVideo
import Foundation
@preconcurrency import WebRTC

public enum OPNVideoPresentationMode: Int, Sendable {
    case balanced = 0
    case smooth = 1
    case lowestLatency = 2

    public var label: String {
        switch self {
        case .balanced: "balanced"
        case .smooth: "smooth"
        case .lowestLatency: "lowest latency"
        }
    }
}

public struct OPNVideoRenderDiagnosticsSnapshot: Equatable, Sendable {
    public var pixelFormat = ""
    public var outputFormat = ""
    public var renderPath = ""
    public var activeTier = ""
    public var fallback = ""
    public var isHDR = false
    public var frameIntervalMs = -1.0
    public var maxFrameIntervalMs = -1.0
    public var framesReceived: UInt64 = 0
    public var framesDrawn: UInt64 = 0
    public var presentationMode = ""
    public var presentLatencyMs = -1.0
    public var presentLatencyMaxMs = -1.0
    public var presentJitterMs = -1.0
    public var contentLeft = 0.0
    public var contentRight = 1.0

    public init() {}
}

/// Presents the Bifrost-free NVST video path on the existing Metal surface.
///
/// Decoded `CVPixelBuffer`s are wrapped as `RTCVideoFrame`s and handed to `MetalVideoView`,
/// which is the same renderer the WebRTC path uses.
@MainActor
public final class NvstBifrostFreeVideoRenderer {
    private let videoView: MetalVideoView
    private let sink: NvstBifrostFreeVideoSink

    /// Thread-safe entry point for the decode thread. `MetalVideoView.renderFrame` and
    /// `setSize` are both nonisolated, so frames never have to hop to the main actor.
    public final class NvstBifrostFreeVideoSink: @unchecked Sendable {
        private weak var videoView: MetalVideoView?
        let lock = NSLock()
        private var lastSize = CGSize.zero
        private var renderedFrames: UInt64 = 0
        private var latestRenderDiagnostics = OPNVideoRenderDiagnosticsSnapshot()
        /// Measures the baked pillarbox regardless of render path or fill mode, so a 16:9 title
        /// can be recognised even with the fill off and the plain
        /// 8-bit renderer drawing. Throttled inside: a 32-row scan a few times a second.
        private let contentDetector = OPNPillarboxDetector()
        /// The most recent decoded frame, kept so a diagnostic snapshot can be written on request
        /// without a screen-recording grant. One buffer retained; the pool has more.
        private var latestPixelBuffer: CVPixelBuffer?
        private let snapshotTransfer = OPNPixelBufferTransfer()

        init(videoView: MetalVideoView) {
            self.videoView = videoView
        }

        public var renderedFrameCount: UInt64 { lock.lock(); defer { lock.unlock() }; return renderedFrames }

        /// The renderer's own account of the last second: decoded surface format, the drawable it
        /// presented into, whether EDR is on, and how many frames it drew versus received.
        var renderDiagnostics: OPNVideoRenderDiagnosticsSnapshot {
            lock.lock()
            defer { lock.unlock() }
            var snapshot = latestRenderDiagnostics
            snapshot.contentLeft = contentDetector.contentRect.left
            snapshot.contentRight = contentDetector.contentRect.right
            return snapshot
        }

        /// Writes the latest decoded frame as a JPEG. 10-bit and 4:4:4 surfaces go through an NV12
        /// transfer first, which is the layout Core Image reads reliably. Returns the frame size.
        func writeLatestFrameJPEG(to url: URL) -> CGSize? {
            lock.lock()
            let buffer = latestPixelBuffer
            lock.unlock()
            guard let buffer,
                  let nv12 = snapshotTransfer.convert(buffer, to: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) else { return nil }
            let image = CIImage(cvPixelBuffer: nv12)
            let context = CIContext(options: [.cacheIntermediates: false])
            guard let data = context.jpegRepresentation(of: image, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!, options: [:]) else { return nil }
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                return nil
            }
            return image.extent.size
        }

        func noteRenderDiagnostics(_ snapshot: OPNVideoRenderDiagnosticsSnapshot) {
            lock.lock()
            latestRenderDiagnostics = snapshot
            lock.unlock()
        }

        public func render(pixelBuffer: CVPixelBuffer, presentationTime: CMTime, isKeyframe: Bool) {
            lock.lock()
            _ = contentDetector.update(with: pixelBuffer)
            latestPixelBuffer = pixelBuffer
            lock.unlock()
            guard let videoView else { return }
            let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            lock.lock()
            let sizeChanged = size != lastSize
            if sizeChanged { lastSize = size }
            renderedFrames &+= 1
            lock.unlock()
            if sizeChanged {
                videoView.setSize(size)
            }
            let buffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
            // The renderer only reads the timestamp for cadence diagnostics; nanoseconds keep it
            // monotonic across the 90 kHz RTP clock.
            let timestampNs = presentationTime.isValid ? Int64(CMTimeGetSeconds(presentationTime) * 1_000_000_000) : 0
            let frame = RTCVideoFrame(buffer: buffer, rotation: ._0, timeStampNs: timestampNs)
            videoView.renderFrame(frame)
        }
    }

    public init(parentView: NSView, targetFps: Int32) {
        let videoView = MetalVideoView(frame: parentView.bounds, targetFps: targetFps, owner: nil)
        videoView.autoresizingMask = [.width, .height]
        videoView.wantsLayer = true
        videoView.layer?.backgroundColor = NSColor.black.cgColor
        parentView.addSubview(videoView)
        self.videoView = videoView
        let sink = NvstBifrostFreeVideoSink(videoView: videoView)
        self.sink = sink
    }

    var renderDiagnostics: OPNVideoRenderDiagnosticsSnapshot { sink.renderDiagnostics }

    func writeLatestFrameJPEG(to url: URL) -> CGSize? { sink.writeLatestFrameJPEG(to: url) }

    public var frameSink: NvstBifrostFreeVideoSink { sink }

    public var isSurfaceReady: Bool {
        videoView.window != nil && !videoView.isHidden && videoView.bounds.width >= 1 && videoView.bounds.height >= 1
    }

    public var renderedFrameCount: UInt64 { sink.renderedFrameCount }

    public func setVideoVisible(_ visible: Bool) {
        videoView.isHidden = !visible
    }

    public func layoutVideoView() {
        guard let superview = videoView.superview else { return }
        if videoView.frame != superview.bounds {
            videoView.frame = superview.bounds
        }
    }

    public func setVideoEnhancement(mode: Int,
                                    sharpness: Int,
                                    denoise: Int,
                                    targetHeight: Int,
                                    pillarboxFillMode: Int,
                                    pillarboxFillDim: Int,
                                    pillarboxFillColor: Int) {
    }

    func writeOffscreenRenderSnapshot(to url: URL) -> CGSize? {
        nil
    }

    func requestRenderSnapshot(to url: URL) {
    }

    func setPresentationMode(_ mode: OPNVideoPresentationMode) {
    }

    public func detach() {
        videoView.renderFrame(nil)
        videoView.removeFromSuperview()
    }
}
