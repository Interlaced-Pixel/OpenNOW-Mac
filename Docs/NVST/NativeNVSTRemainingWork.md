# Native NVST Remaining Work

Distilled from `archive/NativeNVSTFullIntegrationPlan.md` on 2026-08-23 after the plan's phases were
substantially completed. The archived plan remains the source of reversed ABI facts, payload field
inventories, and phase history; `NativeNVSTABI.md` is the living ABI reference. This document tracks
only what is genuinely left.

## Completed Since The Plan Was Written

- Native stats polling bridge: `OpenNOWNativeNVSTGeronimoCopyPerformanceStats` feeds
  `NativeNVSTPerformanceSnapshot` (resolution, FPS, latency, jitter, frame/packet loss, bitrate, codec)
  in `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- Bundle validation wired into CI and release: `scripts/validate-native-nvst-runtime-manifest.sh` and
  `scripts/validate-native-nvst-bundle.sh` run in `.github/workflows/xcode-build.yml` against the built
  app and the re-extracted release zip.
- Authenticated Geronimo lifecycle coverage: `nvstAuthenticatedFreshLaunchPumpsAndStops` and
  `nvstAuthenticatedPauseAndPublicResume` in `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift`, run by
  `.github/workflows/nvst-authenticated.yml` with real credentials.
- Typed `NativeNVSTLaunchPayload` with parity tests (`OPN/Stream/NativeNVSTLaunchPayload.swift`).
- Push-to-talk for the native path (`NativeNVSTPushToTalkState` in `OPN/Stream/NativeWebRTCStreamView.swift`).
- Microphone volume/mode control through the shim (`OpenNOWNativeNVSTGeronimoSetMicrophoneVolume`).
- Stream health monitoring: `NativeNVSTStreamHealthMonitor` detects renderer-unavailable,
  first-frame-timeout, and stalled-stream conditions in `OPN/Stream/NativeNVSTStreamingPath.swift`.

## Remaining Work

### 1. Diagnostics Bridging

- Bridge stream-quality, decoder-state, and HID-capability native callbacks to Swift. Stats are polled;
  these callback-driven channels are not.
- Add operational telemetry for dropped input, focus loss, and unsupported HID capabilities observed in
  authenticated sessions.
- Relevant files: `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`,
  `OPN/Stream/NativeNVSTBifrostTransport.swift`, `Docs/NVST/NativeNVSTABI.md`.

### 2. Audio

- Integrate game volume/mute preferences with the native path; current native audio control covers
  microphone volume only, and game-audio controls are WebRTC-only.
- Handle audio device changes and stream restart/resume on the native path.
- Add capture-permission diagnostics and validate `com.apple.security.device.audio-input` in signed
  builds.
- Relevant files: `OPN/Stream/NativeNVSTBifrostTransport.swift`, `GFN/NVST/Native/NativeNVSTMedia.swift`,
  `OPN/Core/OPNStreamPreferences.swift`.

### 3. UX Gates

- Gate the Native/NVST transport setting on runtime availability. `NVSTNativeRuntime.availability()`
  is currently only exercised by tests; the Settings toggle (`View/Settings/SettingsView.swift`) is
  ungated.
- Add a dedicated native failure surface: exact native phase, sanitized error, retry-native and
  switch-to-WebRTC actions, and copyable diagnostics. Failures currently flow through the generic
  `StreamReport` path with diagnostics metadata (`View/Stream/WebRTCMediaStreamHost.swift`).
- Relevant files: `GFN/NVST/Native/NVSTNativeRuntime.swift`, `View/Settings/SettingsView.swift`,
  `View/Stream/WebRTCMediaStreamHost.swift`.

### 4. Verification

- Authenticated media verification is still manual. The E2E tests prove lifecycle (start, pump, pause,
  resume, stop) but assert no video frames, game audio, microphone, or input behavior.
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

## Verification Commands

- `xcodebuild -project OpenNOW.xcodeproj -scheme OpenNOW -configuration Debug -destination 'platform=macOS' build`
- `scripts/validate-native-nvst-runtime-manifest.sh`
- `scripts/validate-native-nvst-bundle.sh <path-to-OpenNOW.app>`
- Authenticated lifecycle: run the `NVST Authenticated Validation` workflow, or locally with
  `OPN_NVST_E2E_ENABLED=1`, `OPN_NVST_TEST_TOKEN`, and `OPN_NVST_TEST_APP_ID` set, filter
  `NVSTNativeRuntimeTests`.
- `scripts/report-spm-build-size.sh` after SwiftPM-heavy work.
