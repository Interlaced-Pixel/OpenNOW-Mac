# Native NVST ABI Notes

This file records verified NVIDIA ABI facts used to keep the native NVST path safe. Do not treat missing fields as inferred.

## Runtime Artifacts

- `libBifrost2.dylib` exports the raw `nvst*` API and higher-level `nvb*` API.
- `libGeronimo.dylib` imports `nvb*` from `libBifrost2.dylib` and provides the macOS integration layer around session control, VideoToolbox, audio, SDL/input, and GridApp callbacks.
- `libGeronimo.dylib`, `libBifrost2.dylib`, `libGsAudioWebRTC.dylib`, and `SDL2.framework` use `@executable_path/../Frameworks` install names, matching OpenNOW.app embedding.

## Verified Raw `nvst*` Primitives

- `nvstGetVersion()` returns the C string `"14"`.
- `nvstPrepareSignalingServerEndpoint(char const *host, UInt16 port, NvstServerEndpoint_t *out) -> NvstResult_t` returns `0` for a valid host/port.
- `NvstServerEndpoint_t` fields verified through `nvstPrepareSignalingServerEndpoint`:
- `0x00`: host pointer.
- `0x08`: `UInt16` port.
- `0x0c`: `UInt32` transfer protocol, initialized to `5`.
- `0x10`: `UInt32` port usage, initialized to `5`.
- `nvstInitializeStreamConfig(UInt32 mediaType, UInt32 direction, NvstStreamConfig_t *out) -> NvstResult_t` returns `0` for video/audio receiver configs.

## Verified `nvb*` Calling Conventions

- `nvbCreateClient()` takes no arguments and returns an opaque client pointer.
- `nvbDestroyClient(client)` destroys the opaque wrapper returned by `nvbCreateClient` and returns `NVbResult_t`; declaring it as `void` is ABI-unsafe on arm64 because the 0x14-byte result uses hidden result storage.
- `nvbRegisterCallback(client, context, callback)` builds an `NVbCallback_t` from two pointer-sized fields. Field 0 is callback context; field 1 is the callback function. The callback function is invoked as `bool callback(void *context, UInt32 callbackType, void *callbackData)`.
- `nvbSetAuthInfo(client, token, authType)` builds the internal `NVbAuthInfo_t` from a C string token and integer auth type. Verified mappings are `7` for Jarvis, `8` for JWT, and `9` for GFN JWT.
- Geronimo's `GridApp::setAuthInfo(NVbAuthInfo_t&)` forwards a two-field auth struct directly to `SessionControllerImpl::setAuthInfo`; field 0 is the token C string pointer and field 1 is the pointer-sized auth type value.
- Geronimo's initialized `GridApp` stores the Bifrost client pointer at `GridApp + 0x18` on arm64 before calling `nvbRegisterCallback`.
- `GridApp::onNVbCallback(void *, NVbCallbackType_t, NVbCallbackData_t *)` is exported and is the original Geronimo callback target registered with Bifrost.
- OpenNOW leaves Geronimo's Bifrost callback registration intact. It clones the `GridApp` vtable per session and fills the null host `onPrepareResult` and `onStreamingBegin` slots, preserving Geronimo's own callback dispatch and client ownership.
- `nvbStartSession` is not Swift-callable directly because it uses the arm64 C++ struct-return convention.
- Verified arm64 register use at `_nvbStartSession`:
- `x8`: result storage pointer for `NVbResult_t`.
- `x0`: opaque client pointer.
- `x1`: `NVbSessionParams_t const *`.
- `NVbResult_t` is copied as `0x14` bytes by Geronimo callsites after `nvbStartSession` returns.

## Verified `NVbClientInitParams_t` Layout

`nvbInitializeClient` validates and then copies selected `NVbClientInitParams_t` fields into `NVB::BifrostClient` storage.

- Size used by OpenNOW shim: `0xa8` bytes.
- `0x00`: server address C string pointer.
- `0x08`: server port stored as 16-bit value.
- `0x10`: application identifier C string pointer.
- `0x18`: application version C string pointer.
- `0x20`: device id C string pointer.
- `0x28`: profile integer; values must be below `0xb`.
- `0x2c...0x54`: communication parameters copied by Bifrost. Zero values allow Bifrost defaults for connection/data timeouts.
- `0x58`: optional SSL certificate C string pointer.
- `0x60`: optional SSL private-key C string pointer. Certificate and key must either both be null or both be non-null.
- `0x68`: synchronous initialization boolean.
- `0x6c`: converted server type. Synchronous initialization rejects `-1`; OpenNOW maps CloudMatch values `1...5` to `0...4` and `1001` to `0x33` and rejects every other value.
- `0x70`: locale C string pointer.
- `0x78`: keyboard layout C string pointer.
- `0x80`: OS version C string pointer.
- `0x90`: platform C string pointer; Bifrost defaults to `DESKTOP` if null.
- `0x98`: optional `char const **` application headers.
- `0xa0`: application header count.

## Verified `NVbSessionParams_t` Layout

`GridApp::start` and `SessionControl::SessionControllerImpl::startSession(SessionParameters, tracing)` both stack-allocate an `NVbSessionParams_t`, zero it with `bzero(params, 0x208)`, populate it, and pass it to `nvbStartSession`.

- Size: `0x208` bytes.
- `0x00`: `UInt32` app id.
- `0x08`: server address C string pointer.
- `0x10`: server port stored as 16-bit value.
- `0x18`: settings-controlled flag from `GeronimoSettingsImpl`.
- `0x1c`: converted server type copied from `SessionParameters + 0x24`.
- `0x20`: `NVbStreamSettings_t *`.
- `0x28`: stream settings count.
- `0x2c`: codec enum, currently set to `3` by Geronimo before start.
- `0x30`: session-ready boolean, set to `1` before start.
- `NVbStreamSettings_t` entries must provide non-zero 16-bit values at stream-setting offsets `0x10`, `0x12`, and `0x18`; Bifrost logs these as the required resolution/fps fields.
- `0x38...0x13f`: `NVbVideoDecoder_t` / decoder configuration block copied from Geronimo platform state.
- `0x170`: gamepad bitmap.
- `0x174`: copied from `SessionParameters + 0x1cc` / Geronimo session state.
- `0x178`: pointer copied from Geronimo metadata state, then source is cleared.
- `0x180`: count/size copied from Geronimo metadata state, then source is cleared.
- `0x184`: boolean copied from `SessionParameters + 0x234`.
- `0x188`: C string pointer from a Geronimo-owned string at `GridApp + 0x488`.
- `0x1b8`: partner custom data string pointer copied from `SessionParameters + 0x1e8` when present.
- `0x1c0`: client locale C string pointer copied from `SessionParameters + 0x200` when present.
- `0x1c8`: keyboard layout C string pointer copied from `SessionParameters + 0x218` when present.
- `0x1d0`: boolean copied from `SessionParameters + 0x230`.
- `0x1d1`: audio channel count / audio support byte copied from Geronimo state.
- `0x1d2`: boolean copied from `SessionParameters + 0x234`.
- `0x1d4`: connection info count.
- `0x1d8`: `NVbConnectionInfo_t *`.
- `0x1e0`: Bifrost session id C string pointer copied from `SessionParameters + 0x250` when present.
- `0x1e8`: user age copied from `SessionParameters + 0x280`.

## Verified `SessionControl::SessionParameters` Facts

- `SessionParameters` contains non-trivial C++ ownership (`std::string`, vectors). Backing storage must outlive `GridApp::start` until Geronimo/Bifrost no longer references copied C string and vector pointers.
- `GridApp::setNVbSessionParams` copies from `SessionParameters` into GridApp-owned storage before setting `NVbSessionParams_t` pointers.
- `GFNQueryHandler::OnQueryNative` constructs `SessionParameters` at `sp + 0x4d0` and passes it to `GridApp::start` or `GridApp::resume`.
- NVIDIA query fields seen in the start path include `serverAddress`, `tokenType`, `token`, `appId`, `streamingProfile`, `audioModeFormat`, and `session`.
- Geronimo expects `session.connectionInfo[].protocol` as a numeric transport enum. Disassembly verifies `2` maps to the UDP transfer path; emitting an empty string or `0` causes `getStreamStartParameters` to log `Unknown connection protocol detected in the SessionObject. Defaulting to UDP.` OpenNOW defaults missing protocol values to numeric `2` and keeps HTTP/HTTPS scheme selection in `appLevelProtocol`.
- Geronimo's mode-selection deserializer requires `selectedFeatures.prefilterParams.denoiseLevel` and `selectedFeatures.hudStreamingParams.scxQpDelta` to be floating-point JSON numbers. Swift `JSONSerialization` emits integral `Double` values as integers, and the Geronimo parser probe reproduces `0x80f10005` when these fields are `0` instead of `0.0`; OpenNOW post-processes generated mode JSON so integral values remain floating-point literals.
- `GridApp::start(SessionParameters, NVbTracingContext_t)` calls `GridApp::setNVbSessionParams`, parses trace parent into `NVbSessionParams_t + 0x190`, initializes the agent plugin, then calls `SessionControllerImpl::startSession(NVbSessionParams_t)`.
- `Nsk::convertToStreamingParams(StreamStartParameters, VideoDecoderInitParams, NVbStreamingParams_t)` and `Nsk::free(NVbStreamingParams_t&)` are private/non-external symbols in the current Geronimo build. OpenNOW resolves them from the `getStreamStartParameters` image base using verified arm64 text offsets `0x8a060` and `0x89a88`, or x86_64 offsets `0x9d740` and `0x9d3a0`.
- `VideoDecoderInitParams` must not be an all-zero block. `convertToStreamingParams` reads decoder-init fields at `+0x00` and `+0x04`, then dereferences the pointer at `+0x10` and reads `+0x60` from that capability object while choosing platform streaming settings. Passing a null pointer at `+0x10` crashes at address `0x60` before Geronimo can return a failure code.
- `0x00`: app id.
- `0x08`: server address `std::string`.
- `0x20`: server port copied into `NVbSessionParams_t + 0x10`.
- `0x24`: converted server type copied into `NVbSessionParams_t + 0x1c`.
- `0x34`: `NVbStreamSettings_t` count.
- `0x38`: gamepad bitmap.
- `0x40`: supported HID types bitmap consumed by `GeronimoIOInterface::rebuildGamepadBitmap`.
- `0x48`: `NVbStreamSettings_t *`; element stride is `0x170`.
- `0x50`: embedded default `NVbStreamSettings_t` copied when the explicit settings count is zero.
- `0x1cc`: application launch mode.
- `0x1d0`: metadata pointer.
- `0x1d8`: metadata count.
- `0x1dc`: network packet capture flag.
- `0x1e8`: partner custom data `std::string`.
- `0x200`: client locale `std::string`.
- `0x218`: keyboard layout `std::string`.
- `0x230`: allow-keyboard-layout-change flag.
- `0x231`: account-linked flag.
- `0x233`: audio channel count.
- `0x234`: persist-in-game-settings flag.
- `0x238`: network session id `std::string`.
- `0x250`: Bifrost session id `std::string` copied into `NVbSessionParams_t + 0x1e0`.
- `0x268`: `std::vector<NVbConnectionInfo_t>`; element stride is `0x40c`.
- `0x280`: user age copied into `NVbSessionParams_t + 0x1e8`.
- Total verified size: `0x288` bytes.

## Verified `SessionControl::PrepareParameters` Facts

`GridApp::prepare(SessionControl::PrepareParameters const&)` validates and forwards a non-trivial C++ prepare struct into `SessionControllerImpl::prepare`, which constructs the `NVbClientInitParams_t` passed to `nvbInitializeClient`.

- `0x00`: server address `std::string`; must be non-empty.
- `0x18`: server port; must be non-zero.
- `0x1c`: client/profile integer copied into GridApp state.
- `0x20`: device id `std::string`; must be non-empty.
- `0x38`: `NVbCommunicationParams_t` block consumed by `GeronimoSettingsImpl::overrideCommunicationParams`.
- `0x64`: synchronous initialization boolean copied into Bifrost init parameters.
- OpenNOW sets synchronous initialization to `false`; the shim advances its state machine from the asynchronous `onPrepareResult` event delivered by `GridApp::processEvents()`.
- `0x68`: converted server type integer copied into GridApp/Bifrost init state.
- `0x70`: locale `std::string`.
- `0x88`: optional SSL certificate `std::string`.
- `0xa0`: optional SSL private key `std::string`; certificate and key must both be empty or both be present.
- `0xb8`: application identifier `std::string`; OpenNOW sends `GFN-PC`.
- `0xd0`: application version `std::string`; OpenNOW sends `30.0`.
- `0xe8`: client/display name `std::string`, copied into `GridApp + 0x488`.
- `0x100`: client app version `std::string`.
- `0x118`: application header vector; Geronimo converts string entries to `char const *` pointers before Bifrost initialization.

## Verified Native Session Payload Fields

- OpenNOW preserves the raw CloudMatch session JSON for the native path so a future C++ shim can build `SessionControl::SessionParameters` without losing NVIDIA-specific fields.
- The safe Swift payload parser records only start-field presence for telemetry and must not log token values.
- Required native-start inputs tracked before Geronimo startup are `serverAddress`, `tokenType`, `token`, `appId`, `session`, and `streamingProfile.streamingProfileGuid`.
- Geronimo's `getStreamStartParameters` parser expects the normalized session JSON to include a `streamingProfile` object. OpenNOW carries any NVIDIA-provided `streamingProfileGuid` from CloudMatch/session-info/settings; when none is present for OpenNOW's local custom profile, it persists a client-side UUID per app/profile signature and sends that as `streamingProfile.streamingProfileGuid`.
- CloudMatch raw session JSON can omit `tokenType` and `token`. OpenNOW must keep those secrets out of raw/persisted JSON and pass allocation auth as transient C strings into the Geronimo shim before `GridApp::setAuthInfo`.

## Integration Constraints

- Do not call `nvbStartSession` directly from Swift.
- Use a C++/Objective-C++ shim for any `nvb*` API returning or accepting non-trivial C++/large result structs.
- The OpenNOW shim must not create a standalone Bifrost session client for streaming startup; Geronimo owns native client initialization, auth, stream conversion, session start, and stop handling.
- OpenNOW sets auth, requests `GridApp::prepare`, converts and deep-copies streaming parameters, and frees the temporary `NVbStreamingParams_t`. Its main-thread pump then delivers prepare, initializes media, and calls `GridApp::start(SessionControl::SessionParameters, NVbTracingContext_t)` or `GridApp::resume(char const *, SessionParameters, NVbTracingContext_t)`.

## Verified Media/Input Binding Facts

- Geronimo owns video decode/render internally through `SDLWindow`, `VideoDecoderSet`, `VTDecoder`, `MetalAsyncVideoFrameRenderer`, `SDLAudio`, and `WebRTCAudioCapturer`.
- Exported video/render symbols include `VideoDecoderSet::*`, `VTDecoder::*`, `SDLWindow::getNativeWindow`, `SDLWindow::getWindowHandle`, and `SDLWindowManager::createWindow`, but OpenNOW has no exported `GridApp` API to retrieve the active `SDLWindow *`, `IOInterface *`, `NSView`, `CAMetalLayer`, or decoded frame callback.
- Geronimo references `_SDL_CreateWindowFrom`, and private `WindowNativeEventHandler::setCreateFromHandle(void *)` exists, but it is not externally exported and is not safely bindable with `dlsym`.
- The vendored SDL 2.32.10 Cocoa implementation accepts either an `NSWindow *` or `NSView *`, but SDL Metal always inserts its renderer into the owning window's content view. OpenNOW passes a transparent borderless proxy `NSWindow`, then reparents SDL's `CAMetalLayer`-backed view into the real AppKit video surface. The proxy remains attached only for SDL window lifecycle and drawable-size events; no visible renderer window overlaps the app content.
- `SDLWindow::initWindow(SDLWindow::InitParams const&)` reads `SDLWindow::InitParams + 0x70` as the create-from handle. When non-null, Geronimo calls `WindowNativeEventHandler::setCreateFromHandle(handle)` and then `_SDL_CreateWindowFrom(handle)` instead of creating a standalone SDL window. OpenNOW supplies and retains the transparent proxy `NSWindow` for the complete native session; passing a SwiftUI-owned `NSView` directly is unsafe because SDL Metal targets `NSWindow.contentView` rather than the supplied view.
- Native SwiftUI controls use an `NSHostingView` sibling above the embedded Metal surface in the same AppKit container, so controls and video share normal parent-window clipping and z-order.
- `SDLWindowManager::initialize(SDLWindow::InitParams const&)` copies the init params into manager storage starting at `SDLWindowManager + 0x20`, so the stored create-from handle lives at `SDLWindowManager + 0x90`.
- OpenNOW does not mutate `_ZTV16SDLWindowManager` or any other process-global vendor vtable. After prepare succeeds, the per-session shim directly constructs `SDLGraphicsContext`, `SDLEventProcessor`, and one `SDLWindow`, passing the stored native handle at `SDLWindow::InitParams + 0x70`.
- `SDLEventProcessor::InitParams + 0x03` selects SDL input when nonzero. OpenNOW enables this mode to prevent Geronimo's redundant `CocoaInputControllerImpl` from calling AppKit on `InputController.PostQ`; OpenNOW submits keyboard, pointer, text, and gamepad events through `GridApp::sendNvstInputEvent`.
- `SDLWindow::InitParams + 0x1c/+0x20` are the window width and height. Either value being zero makes `SDLWindow::initWindow` call `setFullscreen(true)`, which is invalid for an embedded host window. OpenNOW copies the proxy window's positive content dimensions into these fields and keeps that proxy synchronized with the embedded video surface. `+0x28` is the borrowed title C string, `+0x38` is the high-DPI flag, `+0x70` is the create-from handle, and `+0x78` enables async rendering. The embedded Metal path enables `+0x38` and declares `NSHighResolutionCapable`; disabling Retina rendering produces a half-scale viewport in the top-left quadrant. Zeroed `+0x48/+0x50` is a valid empty `std::shared_ptr`.
- `VideoDecoder::initialize` is virtual at decoder address-point slot `+0x38`. A `VTDecoder` must be initialized through that slot so `VTDecoder::initialize` creates its codec-specific decode-unit transformer at `VTDecoder + 0x250`; calling the exported base implementation directly leaves that member null and crashes on the first `VTDecoder::decode` call. OpenNOW verifies the slot against the exported `VTDecoder::initialize` symbol before invoking it.
- `OpenNOWNativeNVSTGeronimoSetVideoSurface(session, nativeHandle, ...)` stores the OpenNOW proxy `NSWindow` handle before window construction and emits native phase `22`.
- Exported audio symbols include `platformCreateAudioCapturer`, `platformCreateAudioRenderer`, `IOInterface::registerAudioCallback`, `IOInterface::registerAudioCaptureCallback`, `GridApp::sendMicAudioFrame`, `SDLAudio::renderAudio`, and `WebRTCAudioCapturer::*`; OpenNOW has no exported `GridApp` API to retrieve the active `IOInterface *` required for callback registration.
- `GridApp::sendNvstInputEvent(NvstInputEvent_t const&)` is exported and is the safest input-send entry point. `NvstInputEvent_t` is copied as exactly `0x48` bytes, with event type at offset `0x00`.
- Swift `NativeNVSTInputEncoder` emits the verified native `NvstInputEvent_t` representation directly. Every non-text event is exactly `0x48` bytes and is sent synchronously through `GridApp::sendNvstInputEvent`.
- Keyboard event type `1` stores the mapped Darwin key value at `+0x08`, modifiers at `+0x0e`, action `1`/`2` for release/press at `+0x10`, and the microsecond timestamp at `+0x18`.
- Caps-lock event type `15` stores state `1`/`2` for off/on at `+0x08`.
- Mouse event type `2` stores subtype at `+0x08`: movement subtype `1` uses signed deltas at `+0x10/+0x14`, wheel subtype `2` uses signed detents at `+0x24`, and button subtype `3` uses button id at `+0x18` and action at `+0x1c`. Mouse timestamps are at `+0x28`.
- Gamepad event type `18` stores signed 16-bit controls from `+0x08`, source index at `+0x3e`, and microsecond timestamp at `+0x40`. OpenNOW registers each source once through `GridApp::handleGamepadChanged` before sending its first event.
- Text event type `20` stores a borrowed UTF-8 pointer at `+0x08` and a 16-bit byte count at `+0x10`. The shim constructs and sends this event synchronously so the borrowed pointer cannot escape its Swift `Data` lifetime.
- Native Geronimo input does not use OpenNOW's WebRTC data-channel envelope or partially reliable transfer flags.
- Direct `_nvbSendInputEvent` requires the underlying Bifrost client handle, session id, and `NVbResult_t` sret ABI and should not be called from Swift or from a shim that does not own those values.

## Verified Callback Facts

- `nvbEnumToString(0, resultCode)` dispatches to Bifrost's `NVbResultCodeToString`; result `302` is `NVB_R_SESSION_LIMIT_REACHED`.
- `SessionSetUpFailureInfo + 0x00` is the `NVbResultCode_t` delivered to Geronimo lifecycle callbacks. The object also owns strings at `+0x18`, `+0x30`, and `+0x60` and a vector at `+0x48`; OpenNOW does not inspect those opaque fields because their semantics and sensitivity are not verified.
- OpenNOW resolves `nvbEnumToString` from its owned Bifrost handle and synchronously forwards only the static `NVB_R_*` name with callback telemetry. Swift copies the borrowed C string before callback return.
- `GridApp::handleNVbCallback(NVbCallbackType_t, NVbCallbackData_t *)` treats callback type `2` as a Bifrost client event.
- For callback type `2`, `NVbCallbackData_t + 0x00` is the `NVbClientEvent_t` integer used by `GridApp`'s event switch.
- Client event `0x0e` is `SessionNotification`; `GridApp` reads `NVbCallbackData_t + 0x08` as the session notification type.
- Session notification type `1` is `StreamerConnected`; `GridApp` initializes streaming properties, applies server HID capabilities, sets its streaming flag at `GridApp + 0x3c8`, and calls `GeronimoIOInterface::onStreamingBegin` on this notification.
- OpenNOW emits native phases `40`, `44`, and `46` after its start-delivered, streaming-began, and setup-succeeded readiness gates respectively, allowing timeout diagnostics to identify the missing gate.
- OpenNOW treats `callbackType=2`, `clientEvent=14`, `notification=1` as the native readiness gate for `NativeNVSTBifrostTransport.connect`.
- Session notification values in the `50...200` range enter Geronimo's streaming-end path and are treated by OpenNOW as terminal if observed before readiness.
- `_ZTV7GridApp` spans `0x220` bytes through the next symbol. The object address point is `vtable + 0x10`. OpenNOW verifies the original slot values before installing a per-session clone.
- Address-point slots `+0x90` and `+0x98` are null host hooks used for prepare-result and streaming-begin delivery.
- Verified lifecycle slots are `+0xa8` setup failure, `+0xb0` resume failure, `+0xc0` setup success, `+0xc8` streaming terminated, `+0x140` setup progress, `+0x148` active sessions, `+0x158` stop result, and `+0x160` pause result.
- `SessionTerminationInfo` stores termination reason at `+0x00`, extended code at `+0x04`, resumable at `+0x40`, and session-alive at `+0x41`. OpenNOW forwards reason and extended code as native phase `62` and suppresses that terminal event when a local stop is already pending.
- `GridApp::onPrepareResult` queues delivery under `GridApp + 0x430`; `GridApp::processEvents()` swaps and dispatches that queue on its caller. OpenNOW initializes the SDL/audio/video path after successful prepare delivery and before publishing native phase `30` or calling `GridApp::start`.
- `OpenNOWNativeNVSTGeronimoPump` must run on the main thread for the lifetime of the session. Its integer argument is the `SDL_WaitEventTimeout` duration in milliseconds; `0` performs nonblocking `SDL_PumpEvents`/polling. A false `SDLEventProcessor::processEvents` result is terminal.
- Swift keeps the main-thread pump alive while waiting for asynchronous pause and stop callbacks. It cancels and joins the pump before destroying the native session.
- A successful pause destroys local media and GridApp resources without calling `GridApp::stop`, preserving the intentionally paused cloud session for a later resume allocation.
- Normal disconnect calls `GridApp::stop(char const *, int)`, waits for slot `+0x158`, then cancels the pump and destroys the session. Remote termination skips this stop wait because the vendor session is already stopped.
- `GridAppD2` calls `GridApp::uninitialize()` internally. OpenNOW must not call uninitialize a second time, and it keeps the process platform and both dylib handles alive until the destructor returns.
- Destruction restores the embedded Metal view to the retained proxy window, detaches the per-session callback owner and waits for in-flight callbacks, destroys shim-owned media, runs `GridAppD2`, releases the video surface and reference-counted process platform, frees the cloned vtable, and closes the dylib handles.
