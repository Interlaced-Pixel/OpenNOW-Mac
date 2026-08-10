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
- `nvbSetAuthInfo(client, token, authType)` builds the internal `NVbAuthInfo_t` from a C string token and integer auth type. Auth type `9` is used for JWT-like tokens; auth type `8` is used for Jarvis tokens.
- Geronimo's `GridApp::setAuthInfo(NVbAuthInfo_t&)` forwards a two-field auth struct directly to `SessionControllerImpl::setAuthInfo`; field 0 is the token C string pointer and field 1 is the pointer-sized auth type value.
- Geronimo's initialized `GridApp` stores the Bifrost client pointer at `GridApp + 0x18` on arm64 before calling `nvbRegisterCallback`.
- `GridApp::onNVbCallback(void *, NVbCallbackType_t, NVbCallbackData_t *)` is exported and is the original Geronimo callback target registered with Bifrost.
- OpenNOW wraps that callback by re-registering on the same Bifrost client and forwarding every event to `GridApp::onNVbCallback` after recording sanitized callback identifiers.
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
- `0x6c`: server type. Synchronous initialization rejects `-1`; Geronimo paths use `0x34` for this path.
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
- `0x1c`: connection protocol / transport-related integer copied from `SessionParameters + 0x24`.
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
- `0x1b8`: string pointer copied from `SessionParameters + 0x1e8` when present.
- `0x1c0`: client locale C string pointer copied from `SessionParameters + 0x218` when present.
- `0x1c8`: keyboard layout C string pointer copied from `SessionParameters + 0x200` when present.
- `0x1d0`: boolean copied from `SessionParameters + 0x230`.
- `0x1d1`: audio channel count / audio support byte copied from Geronimo state.
- `0x1d2`: boolean copied from `SessionParameters + 0x234`.
- `0x1d4`: connection info count.
- `0x1d8`: `NVbConnectionInfo_t *`.
- `0x1e0`: session id C string pointer copied from `SessionParameters + 0x250` when present.
- `0x1e8`: integer copied from `SessionParameters + 0x280`.

## Verified `SessionControl::SessionParameters` Facts

- `SessionParameters` contains non-trivial C++ ownership (`std::string`, vectors). Backing storage must outlive `GridApp::start` until Geronimo/Bifrost no longer references copied C string and vector pointers.
- `GridApp::setNVbSessionParams` copies from `SessionParameters` into GridApp-owned storage before setting `NVbSessionParams_t` pointers.
- `GFNQueryHandler::OnQueryNative` constructs `SessionParameters` at `sp + 0x4d0` and passes it to `GridApp::start` or `GridApp::resume`.
- NVIDIA query fields seen in the start path include `serverAddress`, `tokenType`, `token`, `appId`, `streamingProfile`, `audioModeFormat`, and `session`.
- Geronimo expects `session.connectionInfo[].protocol` as a numeric transport enum. Disassembly verifies `2` maps to the UDP transfer path; emitting an empty string or `0` causes `getStreamStartParameters` to log `Unknown connection protocol detected in the SessionObject. Defaulting to UDP.` OpenNOW defaults missing protocol values to numeric `2` and keeps HTTP/HTTPS scheme selection in `appLevelProtocol`.
- `GridApp::start(SessionParameters, NVbTracingContext_t)` calls `GridApp::setNVbSessionParams`, parses trace parent into `NVbSessionParams_t + 0x190`, initializes the agent plugin, then calls `SessionControllerImpl::startSession(NVbSessionParams_t)`.
- `Nsk::convertToStreamingParams(StreamStartParameters, VideoDecoderInitParams, NVbStreamingParams_t)` and `Nsk::free(NVbStreamingParams_t&)` are private/non-external symbols in the current Geronimo build. OpenNOW resolves them from the `getStreamStartParameters` image base using verified arm64 text offsets `0x8a060` and `0x89a88`.
- `0x00`: app id.
- `0x08`: server address `std::string`.
- `0x20`: server port copied into `NVbSessionParams_t + 0x10`.
- `0x34`: `NVbStreamSettings_t` count.
- `0x40`: supported HID types bitmap consumed by `GeronimoIOInterface::rebuildGamepadBitmap`.
- `0x48`: `NVbStreamSettings_t *`; element stride is `0x170`.
- `0x50`: embedded default `NVbStreamSettings_t` copied when the explicit settings count is zero.
- `0x1e8`: client app version `std::string`.
- `0x218`: client locale `std::string`.
- `0x238`: keyboard layout `std::string`.
- `0x250`: streaming session id `std::string` copied into `NVbSessionParams_t + 0x1e0`.
- `0x268`: `std::vector<NVbConnectionInfo_t>`; element stride is `0x40c`.
- `0x280`: connection-info flags copied into `NVbSessionParams_t + 0x1e8`.

## Verified `SessionControl::PrepareParameters` Facts

`GridApp::prepare(SessionControl::PrepareParameters const&)` validates and forwards a non-trivial C++ prepare struct into `SessionControllerImpl::prepare`, which constructs the `NVbClientInitParams_t` passed to `nvbInitializeClient`.

- `0x00`: server address `std::string`; must be non-empty.
- `0x18`: server port; must be non-zero.
- `0x1c`: client/profile integer copied into GridApp state.
- `0x20`: application id `std::string`; must be non-empty.
- `0x38`: `NVbCommunicationParams_t` block consumed by `GeronimoSettingsImpl::overrideCommunicationParams`.
- `0x64`: synchronous initialization boolean copied into Bifrost init parameters.
- `0x68`: server type integer copied into GridApp/Bifrost init state; native Geronimo path uses `0x34`.
- `0x70`: locale `std::string`.
- `0x88`: optional SSL certificate `std::string`.
- `0xa0`: optional SSL private key `std::string`; certificate and key must both be empty or both be present.
- `0xb8`: device id `std::string`.
- `0xd0`: platform `std::string`.
- `0xe8`: client/display name `std::string`, copied into `GridApp + 0x488`.
- `0x100`: client app version `std::string`.
- `0x118`: application header vector; Geronimo converts string entries to `char const *` pointers before Bifrost initialization.

## Verified Native Session Payload Fields

- OpenNOW preserves the raw CloudMatch session JSON for the native path so a future C++ shim can build `SessionControl::SessionParameters` without losing NVIDIA-specific fields.
- The safe Swift payload parser records only start-field presence for telemetry and must not log token values.
- Required native-start inputs tracked before Geronimo startup are `serverAddress`, `tokenType`, `token`, `appId`, `session`, and `streamingProfile.streamingProfileGuid`.

## Integration Constraints

- Do not call `nvbStartSession` directly from Swift.
- Use a C++/Objective-C++ shim for any `nvb*` API returning or accepting non-trivial C++/large result structs.
- The OpenNOW shim must not create a standalone Bifrost session client for streaming startup; Geronimo owns native client initialization, auth, stream conversion, session start, and stop handling.
- The native startup sequence is `GridApp::prepare` -> `GridApp::setAuthInfo` -> `Nsk::convertToStreamingParams` -> `GridApp::start(SessionControl::SessionParameters, NVbTracingContext_t)` -> `Nsk::free(NVbStreamingParams_t)`.

## Verified Media/Input Binding Facts

- Geronimo owns video decode/render internally through `SDLWindow`, `VideoDecoderSet`, `VTDecoder`, `MetalAsyncVideoFrameRenderer`, `SDLAudio`, and `WebRTCAudioCapturer`.
- Exported video/render symbols include `VideoDecoderSet::*`, `VTDecoder::*`, `SDLWindow::getNativeWindow`, `SDLWindow::getWindowHandle`, and `SDLWindowManager::createWindow`, but OpenNOW has no exported `GridApp` API to retrieve the active `SDLWindow *`, `IOInterface *`, `NSView`, `CAMetalLayer`, or decoded frame callback.
- Geronimo references `_SDL_CreateWindowFrom`, and private `WindowNativeEventHandler::setCreateFromHandle(void *)` exists, but it is not externally exported and is not safely bindable with `dlsym`.
- `SDLWindow::initWindow(SDLWindow::InitParams const&)` reads `SDLWindow::InitParams + 0x70` as the create-from handle. When non-null, Geronimo calls `WindowNativeEventHandler::setCreateFromHandle(handle)` and then `_SDL_CreateWindowFrom(handle)` instead of creating a standalone SDL window.
- `SDLWindowManager::initialize(SDLWindow::InitParams const&)` copies the init params into manager storage starting at `SDLWindowManager + 0x20`, so the stored create-from handle lives at `SDLWindowManager + 0x90`.
- `_ZTV16SDLWindowManager` is exported. OpenNOW patches the `initialize` and `createManagedWindow` virtual entries to inject the current native video surface handle before Geronimo creates managed SDL windows.
- `OpenNOWNativeNVSTGeronimoSetVideoSurface(session, nativeHandle, ...)` stores the OpenNOW host `NSWindow` handle, installs the `SDLWindowManager` hook, and emits native phase `22` when the hook is ready.
- Exported audio symbols include `platformCreateAudioCapturer`, `platformCreateAudioRenderer`, `IOInterface::registerAudioCallback`, `IOInterface::registerAudioCaptureCallback`, `GridApp::sendMicAudioFrame`, `SDLAudio::renderAudio`, and `WebRTCAudioCapturer::*`; OpenNOW has no exported `GridApp` API to retrieve the active `IOInterface *` required for callback registration.
- `GridApp::sendNvstInputEvent(NvstInputEvent_t const&)` is exported and is the safest input-send entry point. `NvstInputEvent_t` is copied as exactly `0x48` bytes, with event type at offset `0x00`.
- Existing Swift `NativeNVSTInputEncoder` emits OpenNOW/Geronimo-protocol bytes, not a verified native `NvstInputEvent_t`; it must not be sent as native input unless translated into the verified `0x48` native struct.
- Direct `_nvbSendInputEvent` requires the underlying Bifrost client handle, session id, and `NVbResult_t` sret ABI and should not be called from Swift or from a shim that does not own those values.

## Verified Callback Facts

- `GridApp::handleNVbCallback(NVbCallbackType_t, NVbCallbackData_t *)` treats callback type `2` as a Bifrost client event.
- For callback type `2`, `NVbCallbackData_t + 0x00` is the `NVbClientEvent_t` integer used by `GridApp`'s event switch.
- Client event `0x0e` is `SessionNotification`; `GridApp` reads `NVbCallbackData_t + 0x08` as the session notification type.
- Session notification type `1` is `StreamerConnected`; `GridApp` initializes streaming properties, applies server HID capabilities, sets its streaming flag at `GridApp + 0x3c8`, and calls `GeronimoIOInterface::onStreamingBegin` on this notification.
- OpenNOW treats `callbackType=2`, `clientEvent=14`, `notification=1` as the native readiness gate for `NativeNVSTBifrostTransport.connect`.
- Session notification values in the `50...200` range enter Geronimo's streaming-end path and are treated by OpenNOW as terminal if observed before readiness.
