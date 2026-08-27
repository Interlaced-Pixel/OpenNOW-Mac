# Incomplete, Incorrect, and Risky Feature Audit

**Audit date:** 2026-08-24  
**Scope:** PixelNOW macOS streaming, with emphasis on H.265/HEVC over native NVST
**Basis:** Source inspection, existing tests, CI configuration, and `Docs/NVST/NativeNVSTRemainingWork.md`

## Executive summary

Native NVST now has explicit readiness, failure, capability-gating, and diagnostics contracts. It contains a real H.265/HEVC decode and render path, but it does not contain a local NVIDIA NVENC encoder implementation. The `video.encoder*` values in NVST SDP are remote/vendor stream parameters and should not be described as proof that PixelNOW is encoding with NVENC.

The most important gaps are:

1. Authenticated NVST tests require first-frame and sustained-FPS evidence, but audio loopback and input acknowledgement still require a live test environment that exposes those signals.
2. Native codec selection is now capability-gated before Geronimo session creation.
3. The Native/NVST settings toggle and launch selector now check runtime availability.
4. Native microphone permission/setup diagnostics and audio-device change telemetry are wired; game-volume/mute remains intentionally unavailable because the verified ABI exposes no safe per-stream control.
5. Architecture support is now explicit: native NVST is arm64-only because the bundled WebRTC framework has no x86_64 slice.
6. The native frame receiver API is explicitly deprecated for production use; Geronimo remains the native rendering sink.

## Status scale

- **Confirmed incomplete:** The repository explicitly documents the missing behavior or the implementation is visibly absent.
- **High-risk behavior:** The implementation may fail or misreport state under a valid runtime condition, but live evidence is still needed.
- **Verification gap:** The feature may work, but the current tests do not prove it.
- **Intentional:** Looks incomplete by design but is documented as delegation or fallback.

## Findings

### F-01 — Native H.265/NVST media delivery is not verified

**Severity:** High  
**Status:** Partially resolved; authenticated execution required

The authenticated tests now wait for first-frame readiness, assert observed codec/resolution/FPS, require sustained FPS, and verify pause/resume readiness. Direct game-audio samples, microphone loopback, and input acknowledgement remain environment-dependent.

**Evidence**

- `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift:159-211` starts each configured codec, requires first-frame readiness and observed codec/resolution/FPS, verifies sustained performance telemetry, captures diagnostics, and stops cleanly.
- `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift:213-270` verifies first-frame readiness and performance again across pause/resume.
- `/Stream/NativeNVSTStreamingPath.swift:565-629` waits for transport readiness and native renderer readiness before publishing the running state.
- `Docs/NVST/NativeNVSTRemainingWork.md:57-68` records the remaining environment-dependent audio/input evidence and the authoritative Xcode test path.

**Impact**

CI can pass while H.265 produces no visible frames, audio is silent, microphone capture is unavailable, or input is dropped.

**Required completion evidence**

- First-frame timestamp and frame count.
- Sustained frame delivery over a fixed interval.
- Actual codec, dimensions, and pixel format observed at decode/render time.
- Game-audio samples or output-level evidence.
- Microphone capture evidence with permission diagnostics.
- Input delivery evidence.
- Pause/resume continuity and teardown evidence.

### F-02 — Native codec selection is not capability-gated at startup

**Severity:** High  
**Status:** Resolved

User-facing preference resolution correctly checks hardware decode support for H.265 and AV1 in `/Core/StreamPreferences.swift:524-548`. However, native profile construction retains the negotiated codec in `/Stream/NativeNVSTBifrostTransport.swift:959-1023`, and the native decoder is initialized with H.265 (`2`) or AV1 (`4`) in `/NativeGeronimo/NativeNVSTGeronimoShim.mm:2000-2039`.

The native transport now rejects an unsupported negotiated codec immediately before Geronimo startup with a typed `unsupportedCodec` error.

**Impact**

A server-selected H.265 or AV1 session can reach decoder creation on unsupported hardware and fail late, potentially producing a generic startup error instead of deterministic fallback or a precise unsupported-codec message.

**Required fix**

Validate the final negotiated codec against current VideoToolbox capabilities before creating the native session. Choose one explicit policy:

- request H.264 before allocation when the selected codec is unsupported, or
- fail with a typed unsupported-codec error that exposes the codec and capability result.

The fallback must not silently claim native readiness.

### F-03 — The Native/NVST transport toggle is ungated

**Severity:** Medium  
**Status:** Resolved

The setting and transport selector use cached `NVSTNativeRuntime.availability()` results, disable unusable selection, and persist WebRTC when the native runtime is unavailable. Native launch errors expose phase, retry, WebRTC fallback, and copy-diagnostics actions.

**Impact**

Users can enable a transport that cannot load on the current installation and only discover the problem after starting a stream.

**Required fix**

Probe availability before enabling the setting. If unavailable, show the reason and keep WebRTC selected. Native startup errors should expose the phase, a sanitized error, retry-native, switch-to-WebRTC, and copy-diagnostics actions.

### F-04 — Native game-audio controls are incomplete

**Severity:** Medium  
**Status:** Explicit product boundary

The native path exposes microphone controls and permission/setup diagnostics. Geronimo automatically reopens its renderer for channel changes, and PixelNOW records default-device changes. The verified ABI does not expose safe per-stream game-volume/mute control, so the Native/NVST settings UI disables that WebRTC-only control rather than changing global macOS output volume.

**Impact**

The same preferences intentionally behave differently depending on transport. Native output-device hot-swap recovery remains unverified until a safe native audio rebind entry point is available.

**Required completion evidence**

Keep game volume/mute disabled for native NVST until a safe per-stream ABI is verified; retain device-change telemetry and microphone permission diagnostics. Add hot-swap recovery only after the native rebind contract is established.

### F-05 — Architecture support is ambiguous

**Severity:** Medium  
**Status:** Resolved

Native NVST is arm64-only because the bundled WebRTC framework is arm64-only. The runtime rejects other host architectures, the bundle validator requires arm64, and normal/authenticated CI destinations explicitly select arm64.

**Impact**

Historical x86_64 ABI offsets may remain in the reverse-engineering record, but they are not a supported product configuration.

**Required fix**

The supported product configuration is arm64-only; keep runtime checks, bundle validation, and CI aligned with that decision.

### F-06 — Native media receiver API is disconnected from production delivery

**Severity:** Low  
**Status:** Resolved by explicit sink-only contract

`GFN/NVST/Native/NativeNVSTMedia.swift:62-117` defines async video/audio frame streams. `/Stream/NativeNVSTStreamingPath.swift:371-407` exposes them through a media session, but `/Stream/NativeNVSTBifrostTransport.swift:125-231` accepts the receiver without delivering frames to it. The current production rendering path is Geronimo's native SDL/Metal renderer.

**Impact**

Consumers of `videoFrames()` and `audioFrames()` can receive no data even while native rendering works, creating a misleading API contract.

**Required fix**

The frame-stream API is deprecated for production consumers and documents the Geronimo AppKit renderer as the supported native sink. Tests retain the receiver for instrumentation.

### F-07 — Network governor is intentionally inert

**Severity:** Low  
**Status:** Intentional

`/Stream/NativeNVSTNetworkGovernor.swift:9-14` always returns no adjustments. Its tests assert delegation to Bifrost.

This is not a confirmed defect if Bifrost owns network adaptation. The type should be renamed or documented as a vendor-adaptation boundary so an empty implementation is not mistaken for unfinished congestion control.

## H.265/HEVC and NVENC assessment

### What is implemented

- H.265 is recognized as native codec ID `2` in `/Stream/NativeNVSTBifrostTransport.swift:903-909`.
- The Geronimo shim passes the negotiated codec into native VideoToolbox decoder initialization in `/NativeGeronimo/NativeNVSTGeronimoShim.mm:2000-2039`.
- H.265 capability and presentation selection are handled in `/Core/StreamPreferences.swift:524-565`.
- The WebRTC path has H.265 receiver capability detection and offer handling in `/Stream/WebRTCCodecSupport.swift` and `/Stream/WebRTCNativeStreamSession.swift`.
- SDP generation includes vendor `video.encoder*` attributes in `GFN/NVST/SDP/NVSTSessionDescription.swift:306-380`.

### What is not proven

- No project source reference establishes a local NVENC encoder path.
- No `VTCompressionSession` usage appears in PixelNOW source; the matching references are in the vendored WebRTC framework and relate to H.264 encoding.
- The `video.encoder*` SDP attributes describe remote/vendor streaming parameters, not PixelNOW's local encoder implementation.
- Authenticated H.264/H.265 tests now require native first-frame readiness and sustained stream FPS, while direct audio-loopback and input-acknowledgement evidence remains dependent on the configured test environment.

### Correct product wording

Use: **“H.265/HEVC receive and native decode/render support over NVST, subject to runtime capability and live-session verification.”**

Do not use: **“NVENC H.265 encoding in PixelNOW”** unless a local encoder implementation and live encoder telemetry are added and verified.

## Prioritized remediation plan

### P0 — Establish truth in authenticated testing

1. Completed: first-frame and sustained-FPS readiness assertions.
2. Completed: negotiated/observed codec, dimensions, and frame-rate diagnostics.
3. Completed: pause/resume and teardown assertions; audio/input loopback remains dependent on the authenticated environment.
4. Completed: H.264/H.265 selection matrix on the supported arm64 lane; unsupported-codec behavior is covered by capability seams.

### P1 — Make failure behavior deterministic

1. Completed: final native codec selection is gated against VideoToolbox capabilities.
2. Completed: Native/NVST preference and launch selection are gated on runtime availability.
3. Completed: typed failure phases and actionable diagnostics.
4. Completed: arm64-only support is explicit; an attempted x86_64 build is rejected by the arm64-only WebRTC dependency.

### P2 — Close transport parity gaps

1. Resolved by product boundary: game-volume/mute remains WebRTC-only because no safe native per-stream ABI exists; native device-change telemetry and vendor channel-reopen behavior are documented.
2. Completed: audio-input entitlement and permission diagnostics.
3. Completed: native rendering is explicitly Geronimo sink-only.
4. Completed: Bifrost ownership is documented and covered by delegation tests.

## Release recommendation

Native NVST H.265 can be described as capability-gated receive and native decode/render support over NVST, subject to authenticated live-session verification. It must not be described as local NVENC encoding. Release promotion should require the authenticated media workflow and bundled-artifact validation to pass.
