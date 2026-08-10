# Native NVST Full Integration Plan

This is the definitive OpenNOW plan for full native NVST/Geronimo/Bifrost integration. It treats NVIDIA's GeForce NOW macOS app as the source of truth and rejects partial startup, UI fallback, or probe-only implementations as complete work.

## Source Inventory

Authoritative native sources:

- `/Users/jayian/Downloads/GeForceNOW.app/Contents/MacOS/GeForceNOW`: main CEF/native app shell. Contains `GFNQueryHandler::OnQueryNative`, the `QUERY_GFN_PREPARE` and `QUERY_GFN_START` handlers, trace injection, and calls into `GridApp`.
- `/Volumes/Projects/OpenNOW-Mac/vendor/geforcenow/client_mac/client_mac.arm64`: arm64 slice of the main GeForce NOW binary. UUID matches the app arm64 slice.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/libGeronimo.dylib`: Geronimo integration layer. Exact SHA-256 match with `vendor/nvidia-gfn/Frameworks/libGeronimo.dylib`.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/libBifrost2.dylib`: lower Bifrost/NVST session library. Exact SHA-256 match with `vendor/nvidia-gfn/Frameworks/libBifrost2.dylib`.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/libGsAudioWebRTC.dylib`: native audio support. Exact SHA-256 match with `vendor/nvidia-gfn/Frameworks/libGsAudioWebRTC.dylib`.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/SDL2.framework/Versions/A/SDL2`: SDL input/windowing dependency. Exact SHA-256 match with `vendor/nvidia-gfn/Frameworks/SDL2.framework/Versions/A/SDL2`.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/nvc/GFN/libGameStreamClientAgent.dylib`: GameStream telemetry/session IPC agent.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Frameworks/nvc/GFN/GeForceNOWReliabilityMonitor.dylib`: reliability/session monitor and telemetry support.
- `/Users/jayian/Downloads/GeForceNOW.app/Contents/Resources/mall/shared/assets/config/config.json`: native client configuration for CloudMatch, streamer, feature flags, profile support, and Geronimo build identity.
- `/Volumes/Projects/OpenNOW-Mac/vendor/geforcenow/source-readable/apps/gfn-mall/chunks/feature-bundle.chunk-614.js`: readable web client launch flow. Builds the native start payload consumed by `GFNQueryHandler::OnQueryNative`.

Important app config facts:

- GeForce NOW version: `2.0.87.131`.
- Geronimo branch: `gs_04_90`.
- Geronimo cutoff CL: `38582848.0`.
- CloudMatch base: `https://prod.cloudmatchbeta.nvidiagrid.net/`.
- Native client flags: `clientTypeNative=true`, `clientStreamerClassic=true`, `gamepadConfig.implementationType=geronimo`.
- Streamer defaults: port `443`, frame-loss warning timeout `500`, frame-loss error timeout `30000`, reconnect timeout `300000`.

## Native Startup Truth

Native GeForce NOW startup is query-driven:

1. Web client calls CEF `cefQuery`.
2. `GFNQueryHandler::OnQueryNative` reads `command`.
3. `QUERY_GFN_SET_AUTH_INFO` or `QUERY_GFN_PREPARE` sets auth.
4. `QUERY_GFN_PREPARE` builds `SessionControl::PrepareParameters`, calls `GridApp::setAuthInfo`, then `GridApp::prepare`.
5. `QUERY_GFN_START` builds `SessionControl::SessionParameters`, injects `NVbTracingContext_t`, and calls `GridApp::start` or `GridApp::resume`.
6. `GridApp::start` builds `NVbSessionParams_t`, initializes `AgentPluginHandler`, and calls `SessionControllerImpl::startSession(NVbSessionParams_t)`.
7. `SessionControllerImpl::startSession` calls `nvbStartSession`.
8. Geronimo/Bifrost callbacks drive stream setup, streaming-begin, stats, input gates, pause/resume, and termination.

Verified main-app symbols:

- `GFNQueryHandler::OnQueryNative(...)`: `0x1000ba38c`.
- `GFNQueryHandler::ExtractNetworkSessionId(...)`: `0x1000c7884`.
- `injectSpanData(scoped_refptr<CefDictionaryValue>)`: `0x1000df28c`.
- `ConvertServerTypeToNVbServerType(ServerType_t)`: `0x1000b9b78`.
- `BrowserApp::GeronimoInit()`: `0x100013020`.
- `GridApp::setAuthInfo(NVbAuthInfo_t&)`: called at `0x1000bc3bc`.
- `GridApp::prepare(SessionControl::PrepareParameters const&)`: called at `0x1000bc780`.
- `GridApp::resume(char const*, SessionControl::SessionParameters const&, NVbTracingContext_t const&)`: called at `0x1000bef80`.
- `GridApp::start(SessionControl::SessionParameters const&, NVbTracingContext_t const&)`: called at `0x1000bf024`.
- `GridApp::resume(NVbTracingContext_t const&, std::string const&)`: called at `0x1000bbab8`.

Verified query commands:

- `QUERY_GFN_PREPARE`.
- `QUERY_GFN_START`.
- `QUERY_GFN_RESUME`.
- `QUERY_GFN_SET_AUTH_INFO`.
- `QUERY_GFN_SET_AUTH_TOKEN`.

Verified auth token values from web client constants:

- `NVB_AUTH_JWT = 8`.
- `NVB_AUTH_JWT_GFN = 9`.

## Required Native Payload Parity

The start payload built by the readable GeForce NOW web client includes these fields and must be modeled explicitly in OpenNOW:

- `address`.
- `serverType`.
- `port`.
- `appId`.
- `appName`.
- `appLaunchMode`.
- `frameStatsEnabled`.
- `summaryStatsEnabled`.
- `deviceId`.
- `gameShortName`.
- `maxLocalPlayers`.
- `advancedLatencyOptimization`.
- `streamingProfile`.
- `networkPacketCaptureEnabled`.
- `metaData`.
- `frameLossWarningTimeout`.
- `frameLossErrorTimeout`.
- `locale`.
- `digitalStore`.
- `accountLinked`.
- `persistingInGameSettings`.
- `networkSessionId`.
- `audioModeFormat`.
- `supportedControls`.
- `contentRating`.
- `heroImage`.
- `gameDisplayOwnRating`.
- `storeName`.
- `subscriptionLongDesc`.
- `providerName`.
- `zoneName`.
- `userAge`.
- `serverLocation`.
- `gpuNameMap`.
- `streamingDisplayDataInfo`.
- `currentPhysicalResolution`.

The prepare payload must include:

- `address`.
- `port`.
- `deviceId`.
- `clientAppVersion`.
- `tokenType`.
- `token`.
- `serverType`.
- `serverAddress`.
- `spanData` when available.
- locale and client display/platform fields.

Trace context fields:

- `spanData`.
- `ot-tracer-traceid`.
- `ot-tracer-spanid`.
- `ot-tracer-sampled`.
- `traceparent`.

OpenNOW must not reduce this to only `server/token/appId/session/profile`. That is a diagnostic minimum, not native parity.

## Current OpenNOW State

Implemented:

- Native/NVST transport selection and preference storage.
- NVST-shaped CloudMatch session allocation and resume claim request shape.
- Raw CloudMatch session JSON preservation.
- Bifrost/Geronimo runtime loading probes.
- Objective-C++ Geronimo shim with `GridApp::prepare`, `GridApp::setAuthInfo`, `Nsk::convertToStreamingParams`, `GridApp::start`, `Nsk::free`, `GridApp::stop`, and destroy.
- Swift `NativeNVSTStreamingPath` state machine for prepare, allocate, connect, stop.
- Basic payload normalization and telemetry.
- Native runtime embedding in current Xcode project.

Not complete:

- No production video display path.
- No production audio playout path.
- No microphone capture/sending path.
- No native input injection path.
- No `GridApp::resume` path for paused or resumed sessions.
- No pause API or native pause bridge.
- No native stats callback or polling bridge.
- No callback bridge for streamer connected, stream ended, failure, stats, decoder state, or remote termination.
- No complete native payload parity with the web client start payload.
- No app-bundle/archive verification gate for all NVIDIA artifacts.
- No native integration test that proves a real Geronimo start/stop lifecycle with callbacks.

## Architecture Target

OpenNOW should expose a first-class native NVST runtime composed of these layers:

- `NativeNVSTSessionCoordinator`: CloudMatch allocation, claim/resume, server cleanup, and payload preservation.
- `NativeNVSTLaunchPayload`: typed model matching GeForce NOW `QUERY_GFN_PREPARE` and `QUERY_GFN_START` semantics.
- `NativeGeronimoSession`: Objective-C++ owner of `GridApp`, native callbacks, session state, and thread-safe Swift event bridge.
- `NativeNVSTTransport`: Swift actor wrapping the native session, lifecycle calls, input, stats, and media event streams.
- `NativeNVSTRenderer`: SwiftUI/AppKit/Metal rendering surface for decoded native video or native-owned render target.
- `NativeNVSTAudioEngine`: playout, microphone capture, mute/volume/PTT, and device-change handling.
- `NativeNVSTInputRouter`: focused keyboard, mouse, text, gamepad, clipboard, anti-AFK, and direct mouse capture routed into native Geronimo/Bifrost input.
- `NativeNVSTDiagnostics`: structured native phases, errors, stats, callback transitions, and bundle/runtime validation.

## Implementation Phases

### Phase 1: Native Payload Parity

Goal: OpenNOW constructs the same logical prepare/start payload that GeForce NOW sends to `GFNQueryHandler::OnQueryNative`.

Tasks:

- Add `NativeNVSTLaunchPayload` with separate `Prepare` and `Start` models.
- Populate all verified `QUERY_GFN_START` fields from CloudMatch, game metadata, settings, device/display state, and stream preferences.
- Preserve unknown NVIDIA fields as raw JSON alongside typed fields.
- Stop using scattered dictionary lookups in `NativeNVSTBifrostTransport` as the source of truth.
- Pass `spanData` and `traceparent` into `NVbTracingContext_t` instead of using an empty trace parent.
- Forward application headers and signaling query/header information into `PrepareParameters.applicationHeaders` if present.
- Validate required payload sections before allocating or starting native runtime.

Files:

- `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- `OPN/Stream/NativeNVSTSessionPayload.swift`.
- `OPN/GameServices/OpenNOWStreamSessionCoordinator.swift`.
- `OPN/GameServices/OPNSessionManager.swift`.
- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `Tests/Stream/NativeNVSTStreamingPathTests.swift`.
- `Tests/Games/OpenNOWGameServicesTests.swift`.

Exit criteria:

- Unit tests prove a representative GeForce NOW start payload maps to a typed OpenNOW payload without field loss.
- Native shim receives structured prepare/start fields, not ad hoc JSON fragments.
- Missing payload fields fail before native start with a diagnostic that names the missing field.

### Phase 2: Complete Native Lifecycle

Goal: Geronimo owns the full lifecycle: prepare, start, resume, pause, stop, destroy, callback shutdown.

Tasks:

- Add C APIs for `OpenNOWNativeNVSTGeronimoResume`, `OpenNOWNativeNVSTGeronimoPause`, `OpenNOWNativeNVSTGeronimoStop`, state query, and callback registration.
- Resolve and call `GridApp::resume(char const*, SessionParameters const&, NVbTracingContext_t const&)` when CloudMatch returns a paused or claimed session id.
- Resolve and call `GridApp::resume(NVbTracingContext_t const&, std::string const&)` for lightweight native resume when applicable.
- Resolve and call `GridApp::pause` or the underlying session pause path for user-initiated pause.
- Convert `stop` into a result-bearing, awaited lifecycle operation rather than best-effort destroy.
- Maintain native state: created, prepared, sessionStarting, sessionStarted, streaming, paused, stopping, stopped, failed, destroyed.
- Guarantee CloudMatch session cleanup on native start failure after allocation.

Files:

- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- `OPN/Stream/NativeNVSTStreamingPath.swift`.
- `OPN/GameServices/OpenNOWStreamSessionCoordinator.swift`.

Exit criteria:

- Start, resume, pause, stop, destroy are all exposed and tested at the Swift transport layer.
- Failed native starts call `finishSession(..., reason: .failed)` and the coordinator stops the server-side session.
- Native lifecycle telemetry contains result codes and native phase names.

### Phase 3: Callback And Event Bridge

Goal: Swift receives authoritative native callbacks and does not infer stream state from a successful start call.

Tasks:

- Reverse and document `GridApp::handleNVbCallback` event IDs and relevant `NVbCallbackData_t` layouts.
- Add a native callback sink from Objective-C++ to Swift using stable C function pointers and opaque context.
- Emit events for session started, streamer connected, streaming begin, stream failed, stream terminated, audio/video format, stats, decoder state, HID capabilities, and remote end.
- Mark Swift `NativeNVSTStreamingPath` as connected only after native streamer-connected or streaming-begin callback, not after `GridApp::start` returns.
- Add callback-driven disconnect and remote-ended behavior.

Files:

- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `GFN/NVST/Native/NativeNVSTMedia.swift`.
- `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- `OPN/Stream/NativeNVSTStreamingPath.swift`.
- `Docs/NVST/NativeNVSTABI.md`.

Exit criteria:

- A successful launch only becomes UI-ready after native callback confirmation.
- Remote termination produces `.remoteEnded`, not generic failure.
- Callback ABI docs include event IDs, fields, and ownership rules.

### Phase 4: Video Pipeline

Goal: Native NVST video is visible in OpenNOW without WebRTC.

Decision required:

- Option A: Geronimo owns decode/render and OpenNOW embeds or targets the native render surface.
- Option B: OpenNOW receives decoded frames or compressed packets and owns VideoToolbox/Metal rendering.

Preferred direction:

- Preserve Geronimo ownership if `GridApp`/Geronimo already creates the macOS VideoToolbox and render path safely. Do not reimplement decode unless no native render target can be integrated.

Tasks:

- Completed: traced Geronimo render surface creation through `SDLWindowManager`, `SDLWindow::initWindow`, `VideoDecoderSet`, and the native SDL/Metal renderer path.
- Completed: verified `SDLWindow::InitParams + 0x70` as the create-from-handle slot used by `SDL_CreateWindowFrom`.
- Completed: exposed `OpenNOWNativeNVSTGeronimoSetVideoSurface` in the shim and embedded an AppKit host surface in `NativeNVSTMediaStreamSurface`.
- In progress: live verification that SDL wraps the OpenNOW `NSWindow` and presents native NVST frames without stealing or replacing the SwiftUI stream surface.
- If no render target injection exists, bridge decoded `CVPixelBuffer` or compressed frames to Swift and implement `NativeNVSTMetalVideoView`.
- Carry color metadata, HDR, frame pacing, dynamic resolution, rotation/aspect, and black-frame/stall diagnostics.

Files:

- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `View/Stream/WebRTCMediaStreamHost.swift`.
- New `GFN/NVST/Native/NativeNVSTVideoRenderer.swift` or equivalent.
- `GFN/NVST/Native/NativeNVSTMedia.swift`.

Exit criteria:

- A real native NVST stream displays video frames in the OpenNOW stream surface.
- Renderer handles resize, fullscreen/windowed, HDR metadata, and stream stop without leaks.
- Tests or diagnostics detect no-frame and stalled-frame conditions.

### Phase 5: Audio Pipeline

Goal: Native game audio and microphone work end to end.

Tasks:

- Trace whether Geronimo owns game audio playout through `libGsAudioWebRTC` or emits audio frames to clients.
- Expose native audio state and device errors to Swift.
- Integrate game volume/mute preferences.
- Integrate microphone mode, device, push-to-talk, and capture permission.
- Validate `com.apple.security.device.audio-input` behavior in signed app builds.
- Handle audio device change and stream restart/resume.

Files:

- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `GFN/NVST/Native/NativeNVSTMedia.swift`.
- New `GFN/NVST/Native/NativeNVSTAudioEngine.swift` or equivalent.
- `OPN/Core/OPNStreamPreferences.swift`.
- `View/Stream/WebRTCMediaStreamHost.swift`.

Exit criteria:

- Game audio plays through the selected system output.
- Microphone modes work and are visible in telemetry.
- Stop/pause/resume do not leave audio units running.

### Phase 6: Input Pipeline

Goal: Keyboard, mouse, text, gamepad, clipboard, and anti-AFK input reach the native stream.

Tasks:

- Reverse and document `BifrostSDKExecutor::sendNvstInputEvent`, `GeronimoIOInterface::sendNvstInputEvent`, `GridApp::sendNvstInputEvent`, and gating flags `BifrostSDKExecutor + 0x8/+0x9`.
- Add a native `OpenNOWNativeNVSTGeronimoSendInput` API that sends through Geronimo/Bifrost after streaming begin.
- Replace `encodedInputEvents.append` in `NativeNVSTBifrostTransport.send` with actual native send.
- Connect `NativeNVSTMediaStreamSurface` to keyboard, mouse, text, direct mouse lock, gamepad, clipboard, and anti-AFK sources.
- Reuse or adapt `NativeNVSTInput.swift` only if its envelope exactly matches native Geronimo expectations.
- Track dropped input, backpressure, focus loss, and unsupported HID types.

Files:

- `OPN/NativeGeronimo/NativeNVSTGeronimoShim.mm`.
- `GFN/NVST/Native/NativeNVSTInput.swift`.
- `GFN/NVST/Geronimo/GeronimoInputProtocol.swift`.
- `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- `View/Stream/WebRTCMediaStreamHost.swift`.

Exit criteria:

- Production transport sends input to the native stream.
- UI surface captures and forwards all supported input types.
- Gamepad/HID capabilities are reconciled with server capabilities from native callbacks.

### Phase 7: Stats, Diagnostics, And UX

Goal: Native NVST is diagnosable and safe for users.

Tasks:

- Add runtime availability gate before users select Native/NVST.
- Add failure UI with exact native phase, sanitized error, retry native, switch WebRTC, and copy diagnostics.
- Add telemetry for start phases, callbacks, stats, decode, render, audio, input, pause/resume, stop, and cleanup.
- Poll or receive `nvstGetStats`/Geronimo stats.
- Record stream health in the existing HUD/stats UI.
- Add no-token/no-secret enforcement for all logs and telemetry.

Files:

- `OPN/Stream/NativeNVSTBifrostTransport.swift`.
- `OPN/Stream/NativeNVSTStreamingPath.swift`.
- `View/Stream/WebRTCMediaStreamHost.swift`.
- `OPN/Telemetry/*`.
- `GFN/NVST/Native/NVSTNativeRuntime.swift`.

Exit criteria:

- Native failure is actionable and not a generic WebRTC fallback banner.
- Native stats appear in diagnostics/HUD.
- Sensitive values are never logged.

### Phase 8: Packaging, Signing, And Release Gates

Goal: Every delivered build contains the exact native runtime artifacts and can load them under hardened runtime.

Tasks:

- Add a bundle validation script for `OpenNOW.app/Contents/Frameworks`.
- Verify presence, size, hash, install names, rpaths, architecture slices, and signatures for `libGeronimo`, `libBifrost2`, `libGsAudioWebRTC`, and `SDL2`.
- Verify release archives, not only Debug builds.
- Verify notarized/stapled release behavior if applicable.
- Prevent stale archives from being treated as native-capable.

Files:

- `scripts/`.
- `OpenNOW.xcodeproj/project.pbxproj`.
- Release/archive workflow files if present.
- `Tests/GFN/NVST/NVSTNativeRuntimeTests.swift`.

Exit criteria:

- CI or local release script fails if any native artifact is missing or incorrectly signed.
- Debug and Release app bundles both load native runtime from `Bundle.main.privateFrameworksURL`.

## Verification Matrix

Required local commands:

- `swift build --scratch-path .build/shared --target OpenNOW`.
- `xcodebuild -project OpenNOW.xcodeproj -scheme OpenNOW -configuration Debug -destination 'platform=macOS' build`.
- Native Geronimo parser probe from an app-style framework layout.
- Bundle validation script for Debug app.
- Bundle validation script for archived Release app.
- `scripts/report-spm-build-size.sh` after SwiftPM-heavy work.

Required tests:

- Payload parity tests using representative GeForce NOW native start payload fields.
- Runtime loading tests for vendored and app-bundled frameworks.
- Native lifecycle tests using shim-level create, prepare, start, stop where credentials/session data are available.
- Resume and pause unit tests at the Swift transport layer.
- Input-send tests proving the production transport calls native send.
- Failed native start cleanup tests proving CloudMatch sessions are stopped.
- UI tests for Native/NVST selection, failure diagnostics, and input focus capture.

Known current blocker:

- `swift test --scratch-path .build/shared --filter NativeNVST` fails before running the filter because unrelated Swift 6 actor-isolation errors exist in `Tests/GFN/Starfleet/StarfleetTests.swift` and other test compilation units. This must be fixed or isolated before Native NVST test gates can be trusted.

## Non-Negotiable Rules

- Do not call `nvbStartSession` directly from Swift.
- Do not mark Native/NVST connected until native callback state confirms streamer connection or streaming begin.
- Do not treat `GridApp::start` returning success as media readiness.
- Do not replace missing native media/input with WebRTC or mock streams.
- Do not drop unknown NVIDIA payload fields if they can be preserved.
- Do not log tokens, raw auth headers, or secret session data.
- Do not ship a generic “switch to WebRTC” failure as the only Native/NVST diagnostic.
- Do not call a probe-only runtime path complete.

## Immediate Next Work

1. Implement typed `NativeNVSTLaunchPayload` and parity tests against the extracted GeForce NOW start payload field set.
2. Add native callback registration and state event bridging before UI readiness.
3. Add `GridApp::resume` and pause APIs to the shim.
4. Trace Geronimo render target ownership and decide native-owned render target vs OpenNOW-owned VideoToolbox/Metal rendering.
5. Replace buffered input with real Geronimo/Bifrost native input send.
6. Add native bundle validation script and run it against Debug and Release app bundles.
