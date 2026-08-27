# Native NVST Remaining Work

Distilled from `archive/NativeNVSTFullIntegrationPlan.md` on 2026-08-23 after the plan's phases were
substantially completed. The archived plan remains the source of reversed ABI facts, payload field
inventories, and phase history; `NativeNVSTABI.md` is the living ABI reference. This document tracks
only what is genuinely left.

## Completed Since The Plan Was Written

- Native stats polling bridge: `NativeNVSTGeronimoCopyPerformanceStats` feeds
  `NativeNVSTPerformanceSnapshot` (resolution, FPS, latency, jitter, frame/packet loss, bitrate, codec)
  in `/Stream/NativeNVSTBifrostTransport.swift`.
- Bundle validation wired into CI and release: `scripts/validate-native-nvst-runtime-manifest.sh` and
  `scripts/validate-native-nvst-bundle.sh` run in `.github/workflows/xcode-build.yml` against the built
  app and the re-extracted release zip.
- Authenticated Geronimo lifecycle coverage: `nvstAuthenticatedFreshLaunchPumpsAndStops` and
  `nvstAuthenticatedPauseAndPublicResume` in `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift`, run by
  `.github/workflows/nvst-authenticated.yml` with real credentials.
- Typed `NativeNVSTLaunchPayload` with parity tests (`/Stream/NativeNVSTLaunchPayload.swift`).
- Push-to-talk for the native path (`NativeNVSTPushToTalkState` in `/Stream/NativeWebRTCStreamView.swift`).
- Microphone volume/mode control through the shim (`NativeNVSTGeronimoSetMicrophoneVolume`).
- Stream health monitoring: `NativeNVSTStreamHealthMonitor` detects renderer-unavailable,
  first-frame-timeout, and stalled-stream conditions in `/Stream/NativeNVSTStreamingPath.swift`.

## Remaining Work

### 1. Diagnostics Bridging

- Stream-quality and decoder readiness are now exposed through the native readiness snapshot and the
  polled performance telemetry path. HID-capability callback fields remain vendor-owned and are not
  exposed until their ABI is verified.
- Dropped input and focus-loss telemetry are emitted by the native input host.
- Relevant files: `/NativeGeronimo/NativeNVSTGeronimoShim.mm`,
  `/Stream/NativeNVSTBifrostTransport.swift`, `Docs/NVST/NativeNVSTABI.md`.

### 2. Audio

- Native audio setup is now part of the readiness contract and microphone permission/setup failures
  are surfaced with sanitized diagnostics. The signed target includes
  `com.apple.security.device.audio-input`.
- Game volume/mute remains intentionally unsupported by the verified Geronimo ABI. The native path
  must not change global macOS output volume as a substitute; keep the control disabled or use
  WebRTC when per-stream game-audio control is required.
- Default audio-device hot-swap recovery remains pending until a safe native audio rebind entry point
  is verified.
- Relevant files: `/Stream/NativeNVSTBifrostTransport.swift`, `GFN/NVST/Native/NativeNVSTMedia.swift`,
  `/Core/StreamPreferences.swift`.

### 3. UX Gates

- The Native/NVST transport setting and transport selector are gated on runtime availability.
- Native startup failures expose the failure phase, sanitized error, retry-native, switch-to-WebRTC,
  and copy-diagnostics actions in `View/Stream/WebRTCMediaStreamHost.swift`.
- Relevant files: `GFN/NVST/Native/NVSTNativeRuntime.swift`, `/Stream/StreamTransportSelection.swift`,
  `View/Settings/SettingsView.swift`, `View/Stream/WebRTCMediaStreamHost.swift`.

### 4. Verification

- Authenticated tests now require first-frame performance evidence, sustained stream FPS, negotiated
  codec/resolution, pause/resume readiness, and teardown success. Direct game-audio, microphone
  sample, and input-loopback evidence still requires a test account/session that exposes those
  signals.
- Obtain runtime evidence for whether a live server session ever produces Bifrost's private internal
  resume event; do not expose that path without evidence.
- Re-check the SwiftPM test-filter path: as of 2026-08-18,
  `swift test --scratch-path .build/shared --filter NativeNVST` failed before reaching the filter due
  to unrelated Swift 6 actor-isolation errors in other test compilation units. CI now gates on
  `xcodebuild test`; confirm whether the SwiftPM path still fails.

## Non-Negotiable Rules (Carried Forward)

- Do not call `nvbStartSession` directly from Swift.
- Do not mark Native/NVST connected until native callback state confirms streamer connection or
  streaming begin.
- Do not treat `GridApp::start` returning success as media readiness.
- Do not replace missing native media/input with WebRTC or mock streams.
- Do not drop unknown NVIDIA payload fields if they can be preserved.
- Do not log tokens, raw auth headers, or secret session data.
- Do not ship a generic "switch to WebRTC" failure as the only Native/NVST diagnostic.
- Do not call a probe-only runtime path complete.
- Native NVST support is arm64-only. The bundled WebRTC framework has no x86_64 slice, so the
  runtime rejects Intel execution and CI validates the arm64 configuration.

## Verification Commands

- `xcodebuild -project PixelNOW.xcodeproj -scheme PixelNOW -configuration Debug -destination 'platform=macOS,arch=arm64' build`
- `scripts/validate-native-nvst-runtime-manifest.sh`
- `scripts/validate-native-nvst-bundle.sh <path-to-PixelNOW.app>`
- Authenticated lifecycle: run the `NVST Authenticated Validation` workflow, or locally with
  `_NVST_E2E_ENABLED=1`, `_NVST_TEST_TOKEN`, and `_NVST_TEST_APP_ID` set, filter
  `NVSTNativeRuntimeTests`.
- `scripts/report-spm-build-size.sh` after SwiftPM-heavy work.
