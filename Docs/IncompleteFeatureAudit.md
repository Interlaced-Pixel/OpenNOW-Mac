# Incomplete, Incorrect, and Risky Feature Audit

**Audit date:** 2026-08-24  
**Scope:** OpenNOW macOS streaming, with emphasis on H.265/HEVC over native NVST  
**Basis:** Source inspection, existing tests, CI configuration, and `Docs/NVST/NativeNVSTRemainingWork.md`

## Executive summary

Native NVST is not complete enough to treat as release-verified media transport. The code contains a real H.265/HEVC decode and render path, but it does not contain a local NVIDIA NVENC encoder implementation. The `video.encoder*` values in NVST SDP are remote/vendor stream parameters and should not be described as proof that OpenNOW is encoding with NVENC.

The most important gaps are:

1. Authenticated NVST tests verify lifecycle only, not delivered video, audio, microphone, or input.
2. Native codec selection can preserve a negotiated H.265 or AV1 value without rejecting it when the local decoder cannot support it.
3. The Native/NVST settings toggle is available without checking runtime availability.
4. Native audio controls are incomplete: microphone control exists, but game-volume/mute and audio-device recovery are not wired through the native path.
5. Architecture validation and CI are arm64-only even though runtime parsing supports x86_64.
6. A native frame receiver abstraction exists, but the transport does not currently deliver decoded frames to it; rendering is delegated to Geronimo.

## Status scale

- **Confirmed incomplete:** The repository explicitly documents the missing behavior or the implementation is visibly absent.
- **High-risk behavior:** The implementation may fail or misreport state under a valid runtime condition, but live evidence is still needed.
- **Verification gap:** The feature may work, but the current tests do not prove it.
- **Intentional:** Looks incomplete by design but is documented as delegation or fallback.

## Findings

### F-01 — Native H.265/NVST media delivery is not verified

**Severity:** High  
**Status:** Verification gap

The authenticated tests start a native session, wait, pause/resume, and stop successfully. They do not assert that a decoded frame reached the renderer, that frames continued arriving, or that audio, microphone, and input worked.

**Evidence**

- `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift:158-193` starts a session, sleeps for five seconds, stops, and checks only `report.success`.
- `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift:195-229` exercises pause/resume lifecycle without media assertions.
- `OPN/Stream/NativeNVSTStreamingPath.swift:458-492` marks the path connected after transport connection/readiness and before an independently asserted first rendered frame.
- `Docs/NVST/NativeNVSTRemainingWork.md:57-66` explicitly records authenticated media verification as outstanding.

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
**Status:** High-risk behavior

User-facing preference resolution correctly checks hardware decode support for H.265 and AV1 in `OPN/Core/OPNStreamPreferences.swift:524-548`. However, native profile construction retains the negotiated codec in `OPN/Stream/NativeNVSTBifrostTransport.swift:959-1023`, and the native decoder is initialized with H.265 (`2`) or AV1 (`4`) in `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm:2000-2039`.

There is no equivalent final guard that rejects an unsupported negotiated codec immediately before native startup.

**Impact**

A server-selected H.265 or AV1 session can reach decoder creation on unsupported hardware and fail late, potentially producing a generic startup error instead of deterministic fallback or a precise unsupported-codec message.

**Required fix**

Validate the final negotiated codec against current VideoToolbox capabilities before creating the native session. Choose one explicit policy:

- request H.264 before allocation when the selected codec is unsupported, or
- fail with a typed unsupported-codec error that exposes the codec and capability result.

The fallback must not silently claim native readiness.

### F-03 — The Native/NVST transport toggle is ungated

**Severity:** Medium  
**Status:** Confirmed incomplete

`View/Settings/SettingsView.swift:1154-1160` always displays the Native/NVST toggle. `ViewModel/CatalogViewModel.swift:1526-1530` saves the preference without checking runtime availability. `NVSTNativeRuntime.availability()` is available in `GFN/NVST/Native/NVSTNativeRuntime.swift:129-137`, but the setting does not use it.

**Impact**

Users can enable a transport that cannot load on the current installation and only discover the problem after starting a stream.

**Required fix**

Probe availability before enabling the setting. If unavailable, show the reason and keep WebRTC selected. Native startup errors should expose the phase, a sanitized error, retry-native, switch-to-WebRTC, and copy-diagnostics actions.

### F-04 — Native game-audio controls are incomplete

**Severity:** Medium  
**Status:** Confirmed incomplete

The native path exposes microphone controls, but the remaining-work document states that game volume/mute and audio-device changes are not integrated. `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm:2614-2621` exposes microphone volume, while the game and microphone volume controls in `OPN/Stream/WebRTCNativeStreamSession.swift:388-392` are associated with WebRTC.

**Impact**

The same preferences can behave differently depending on transport. Output-device changes may leave native audio silent or stale after restart/resume.

**Required fix**

Wire game volume and mute through native NVST, observe output-device changes, rebind or restart native audio on device changes, and validate microphone permission plus `com.apple.security.device.audio-input` in signed builds.

### F-05 — Architecture support is ambiguous

**Severity:** Medium  
**Status:** Verification gap

`GFN/NVST/Native/NVSTNativeRuntime.swift:194-215` parses both arm64 and x86_64 Mach-O slices, and the runtime manifest validator checks both architectures. However, `scripts/validate-native-nvst-bundle.sh:36-40` checks only for an arm64 slice, and both normal and authenticated CI jobs use `destination 'platform=macOS,arch=arm64'`.

**Impact**

The project either carries an unverified Intel-support claim or has unnecessary x86_64 handling that can drift unnoticed.

**Required fix**

Declare Intel unsupported everywhere if that is intentional, or add x86_64 bundle validation and an Intel build/test lane.

### F-06 — Native media receiver API is disconnected from production delivery

**Severity:** Low  
**Status:** Suspicious abstraction

`GFN/NVST/Native/NativeNVSTMedia.swift:62-117` defines async video/audio frame streams. `OPN/Stream/NativeNVSTStreamingPath.swift:371-407` exposes them through a media session, but `OPN/Stream/NativeNVSTBifrostTransport.swift:125-231` accepts the receiver without delivering frames to it. The current production rendering path is Geronimo's native SDL/Metal renderer.

**Impact**

Consumers of `videoFrames()` and `audioFrames()` can receive no data even while native rendering works, creating a misleading API contract.

**Required fix**

Either bridge actual decoded media into the receiver, or remove/deprecate the frame-stream API and document that native rendering is sink-only. Do not leave both contracts implied.

### F-07 — Network governor is intentionally inert

**Severity:** Low  
**Status:** Intentional

`OPN/Stream/NativeNVSTNetworkGovernor.swift:9-14` always returns no adjustments. Its tests assert delegation to Bifrost.

This is not a confirmed defect if Bifrost owns network adaptation. The type should be renamed or documented as a vendor-adaptation boundary so an empty implementation is not mistaken for unfinished congestion control.

## H.265/HEVC and NVENC assessment

### What is implemented

- H.265 is recognized as native codec ID `2` in `OPN/Stream/NativeNVSTBifrostTransport.swift:903-909`.
- The Geronimo shim passes the negotiated codec into native VideoToolbox decoder initialization in `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm:2000-2039`.
- H.265 capability and presentation selection are handled in `OPN/Core/OPNStreamPreferences.swift:524-565`.
- The WebRTC path has H.265 receiver capability detection and offer handling in `OPN/Stream/WebRTCCodecSupport.swift` and `OPN/Stream/WebRTCNativeStreamSession.swift`.
- SDP generation includes vendor `video.encoder*` attributes in `GFN/NVST/SDP/NVSTSessionDescription.swift:306-380`.

### What is not proven

- No project source reference establishes a local NVENC encoder path.
- No `VTCompressionSession` usage appears in OpenNOW source; the matching references are in the vendored WebRTC framework and relate to H.264 encoding.
- The `video.encoder*` SDP attributes describe remote/vendor streaming parameters, not OpenNOW's local encoder implementation.
- Existing H.265 tests are primarily preference, SDP, and payload-parity tests; they do not prove a live H.265 NVST frame was decoded and rendered.

### Correct product wording

Use: **“H.265/HEVC receive and native decode/render support over NVST, subject to runtime capability and live-session verification.”**

Do not use: **“NVENC H.265 encoding in OpenNOW”** unless a local encoder implementation and live encoder telemetry are added and verified.

## Prioritized remediation plan

### P0 — Establish truth in authenticated testing

1. Add first-frame and sustained-frame assertions.
2. Record negotiated and observed codec, dimensions, and frame rate.
3. Assert game audio, microphone, input, pause/resume, and teardown.
4. Run the matrix for H.264 and H.265 on supported and unsupported hardware.

### P1 — Make failure behavior deterministic

1. Gate final native codec selection against VideoToolbox capabilities.
2. Gate the Native/NVST preference on runtime availability.
3. Add typed failure phases and actionable diagnostics.
4. Decide and document Intel support.

### P2 — Close transport parity gaps

1. Add native game-volume/mute and device-change handling.
2. Add audio-input entitlement and permission diagnostics.
3. Resolve the frame-receiver API contract.
4. Document the network-governor delegation boundary.

## Release recommendation

Do not describe native NVST H.265 as fully complete or NVENC-backed yet. The implementation is substantial and likely functional on the intended arm64 configuration, but release confidence is limited until P0 media assertions prove that the negotiated H.265 stream produces usable video/audio/input behavior and P1 prevents unsupported native startup from failing late.
