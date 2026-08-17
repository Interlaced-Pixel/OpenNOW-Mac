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
- Bifrost validates clients against an image-local registry. Calls involving a Geronimo-created client must use the exact `nvbCreateClient` and `nvbRegisterCallback` targets bound in Geronimo's import table; resolving either function through a different loaded image produces `NVB_R_INVALID_CLIENT_OBJECT`.
- Bifrost callback registration is single-assignment. During serialized `GridApp::initialize`, OpenNOW leaves the first SessionController client registration unchanged, intercepts creation of the second GridApp client, registers a callback that invokes `GridApp::onNVbCallback` first and then observes verified haptic events, acknowledges Geronimo's immediately following registration, and restores both imports. It does not attempt rejected post-initialization callback replacement and does not change Bifrost client ownership.
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
- `0x1d0`: metadata pointer to a contiguous `NVbKeyValuePair_t` array.
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

## Verified Native Metadata ABI

- `NVbKeyValuePair_t` is exactly `0x10` bytes with 8-byte alignment: `char const *key` at `+0x00` and `char const *value` at `+0x08`.
- Geronimo receives the pair-array pointer at `SessionParameters + 0x1d0` and its element count at `+0x1d8`.
- OpenNOW accepts only the vendor-shaped top-level `metaData` JSON array. Every element must be an object whose `key` and `value` fields are JSON strings. Values are copied byte-for-byte as UTF-8 without coercion or whitespace trimming; empty strings are valid, while embedded nulls are rejected because the native fields are C strings.
- Metadata is ordered and duplicate keys are retained. Consumers that apply entries in order therefore receive the vendor's natural duplicate-last behavior.
- Missing `metaData` means no metadata. A non-array value, non-object element, missing field, or non-string key/value rejects the complete native start rather than filtering individual entries.
- The array is checked before iteration and capped at 64 entries. An array of 65 or more entries is rejected explicitly.
- `PendingStart` owns every key/value `std::string` across asynchronous prepare. It creates the contiguous `NVbKeyValuePair_t` pointer array only immediately before synchronous `GridApp::start` or `GridApp::resume`; neither owned strings nor the pointer array mutate during that call.

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

## Verified Feature-Control and Network QoS Facts

- `GridApp::controlFeatures(NVbFeatureControlType_t, UInt32) -> bool` is exported as `_ZN7GridApp15controlFeaturesE23NVbFeatureControlType_tj`. It forwards through the initialized `IOInterface` with its enable argument fixed to `true`; it is not safe before `GridApp::initialize` has installed that interface.
- `IOInterface::controlFeatures(NVbFeatureControlType_t, UInt32, bool) -> bool` and `BifrostSDKExecutor::controlFeatures(NVbFeatureControlType_t, UInt32, bool) -> bool` are exported as `_ZN11IOInterface15controlFeaturesE23NVbFeatureControlType_tjb` and `_ZN18BifrostSDKExecutor15controlFeaturesE23NVbFeatureControlType_tjb`.
- The generic executor stores the latest value in its feature map before checking whether Bifrost is active. When active, it constructs an `NVbFeatureControl_t` with the 32-bit type at `+0x00`, enabled value at `+0x04`, and disabled value at `+0x08`, then calls `nvbFeatureControl`. The generic map has no exported getter and is not proof that the server or transport applied a value.
- `nvbFeatureControl` uses the large `NVbResult_t` return convention: `x8` is result storage, `x0` is the Bifrost client, `x1` is the session id string, and `x2` points to `NVbFeatureControl_t`.
- The request path is `nvbFeatureControl` to `NVB::BifrostClient::featureControl` to `NVB::SessionController::featureControl` to `NVB::Streamer::featureControl`.
- `NVB::Streamer::featureControl` rejects feature types above `0x1a`. Its complete arm64 jump table is:

| Type | Verified behavior |
| --- | --- |
| `0x00` | Hardware cursor capture |
| `0x01` | Client network capture diagnostic |
| `0x02` | Server network capture diagnostic |
| `0x03` | Client stats recording diagnostic |
| `0x04` | Server trace recording diagnostic |
| `0x05` | Mouse acceleration |
| `0x06` | Gamepad haptics |
| `0x07` | Mouse sensitivity |
| `0x08` | Tracking remote cursor image |
| `0x09` | Performance indicator |
| `0x0a` | Mouse settings input event |
| `0x0b` | Content-capture alpha format |
| `0x0c` | VSync interval |
| `0x0d` | Present-completed timestamp control |
| `0x0e` | Reserved and rejected with result `0x65` in this build |
| `0x0f` | Dynamic resolution/frame-rate control mode |
| `0x10` | Maximum streaming bitrate |
| `0x11` | Stutter indicator |
| `0x12` | Remote-input device/controller overlay |
| `0x13` | L4S state |
| `0x14` | Video-quality snapshot |
| `0x15` | True HDR parameters |
| `0x16` | Prefilter parameters |
| `0x17` | HUD streaming/SCX delta-QP parameters |
| `0x18` | QP delta-map view |
| `0x19` | Video modifiers |
| `0x1a` | Reflex latency flash indicator overlay |

- None of the 27 feature-control cases accepts a DSCP value, IP traffic class, arbitrary ECN codepoint, QoS traffic type, or congestion-control policy.
- `GridApp::setDynamicStreamingMode(UInt16, UInt32) -> bool` and `GridApp::setStreamingMaxBitrate(UInt16, UInt32) -> bool` use feature types `0x0f` and `0x10`. Both requests store the stream index at `+0x04` and the 32-bit value at `+0x08`; their executor state changes only after `nvbFeatureControl` succeeds.
- `IOInterface::getDynamicStreamingMode() -> UInt32` and `IOInterface::getMaxBitrateKbps() -> UInt32` are local accepted-state readbacks. Their no-executor defaults are `3` and `35000` Kbps.
- `GridApp::setL4sState(UInt16, bool) -> bool`, `IOInterface::setL4sState(UInt16, bool) -> bool`, and `BifrostSDKExecutor::setL4sState(UInt16, bool) -> bool` are exported as `_ZN7GridApp11setL4sStateEtb`, `_ZN11IOInterface11setL4sStateEtb`, and `_ZN18BifrostSDKExecutor11setL4sStateEtb`.
- The named L4S request uses feature type `0x13`, stream index at request `+0x04`, and Boolean state at `+0x06`. The executor changes its accepted-state byte at `+0x2c` only after `nvbFeatureControl` returns success.
- `IOInterface::getL4sState() -> UInt32` reads the executor's accepted-state byte. It returns `1` when no executor exists. This is local accepted-state readback, not an independent server-state query.
- The L4S transport path is feature type `0x13` to NVST message type `0x0c`, then `ClientSession::sendL4sStateChange(UInt32, bool)`. Only after that send succeeds does `SignalingHandler::toggleEcnMarking(bool)` call `WebRtcTransport::setEcn(EcnField_t)` on the active transport.
- Disabling L4S selects ECN field value `0`. Enabling it selects field value `2` or `1` from NVIDIA's general setting at `+0x2cd8`; invalid configured values fall back to `0`. The application controls only the L4S Boolean and cannot choose the ECN codepoint through this ABI.
- Bifrost contains internal network setters, including `NetworkRtpSink::{setDscpValue,setQosTrafficType,enableEcn}`, `UdpRtpSource::{setDscpValue,setQosTrafficType,setReceiveTosInfo}`, `WebRtcTransport::{setDscpValue,socketDscpEnable,setEcn,setReceiveTosInfo}`, `NattHolePunch::setDscpValue`, and `NvNetworkPlatformInterface::{socketDscpEnable,socketDscpUpdate,socketSetSendWithEcn,socketSetReceiveTosInfo}`.
- `WebRtcTransport` and `ClientSession` control methods are private symbols. The externally visible `NetworkRtpSink`, `UdpRtpSource`, `NattHolePunch`, and `NvNetworkPlatformInterface` methods still require an active session-owned object pointer or socket descriptor that no exported `GridApp`, `IOInterface`, executor, or `nvb*` API returns.
- `UdpRtpSourceCreate` and the exported transport constructors create new unrelated transport objects; they do not acquire the active stream transport. Constructing one cannot control the session already owned by Bifrost.
- `ClientSession::sendQosPreferenceChange(UInt32, UInt32)` is an internal dynamic-streaming-mode command, not an application-owned arbitrary QoS setter.
- Therefore L4S is the only verified application-owned ECN/QoS-related runtime control. Direct DSCP, traffic-class, ECN-codepoint, and QoS-traffic-type controls must remain unexposed until NVIDIA provides an owned acquisition API and an applied-state readback path.

## Verified Resume and Endpoint Replacement Facts

- `NVbConnectionInfo_t` has element stride `0x40c`. Geronimo converts each populated record into a 24-byte NVST endpoint value, preserving source order for up to 20 records; index `0` is the first endpoint returned by the internal getters.
- Streamer initialization copies all 20 connection-info slots into streamer-owned configuration. The endpoint-prioritization callback is a post-connect notification: callback mutations and the callback return value do not alter the configured endpoint order.
- `GridApp::resume(char const *, SessionParameters const&, NVbTracingContext_t const&)` eventually invokes public `BifrostClient::resumeSession`. Bifrost accepts this operation only when the existing client is in state `8` and requires the replacement `SessionController` to begin in state `0`.
- Public resume removes the previous controller from the session map, constructs a new controller and streamer, copies the `0x208`-byte Bifrost session-parameter block, and submits `setUpSession` with action `2`. An accepted asynchronous submission moves the new controller to state `6`; successful seat provisioning moves it to state `9`.
- Geronimo deep-copies `SessionParameters.connectionInfo` into owned storage before invoking Bifrost. Caller-owned session-parameter storage only needs to remain valid through that synchronous Geronimo copy.
- Resume provisioning, not the caller's input connection array, supplies the authoritative replacement endpoints. On success, Geronimo rebuilds `NVbStreamingParams_t` from returned `SessionInfo.connectionInfo`, and streaming startup deep-copies those records into the new streamer.
- Immediate resume rejection returns synchronously as `NVbResult_t`. Verified result codes include `1` (`NVB_R_UNINITIALIZED`), `101` (`NVB_R_INVALID_PARAM`), `102` (`NVB_R_INVALID_CLIENT_OBJECT`), `105` (`NVB_R_INVALID_VIDEO_DECODER`), `106` (`NVB_R_INVALID_AUDIO_RENDERER`), `108` (`NVB_R_INVALID_STREAM_SETTINGS`), and `114` (`NVB_R_INVALID_INPUT_DEVICE`).
- An asynchronous action-2 provisioning failure emits Bifrost client event `9`. Geronimo queues that event, and `GridApp::processEvents()` dispatches `GridApp::onResumeFailure` through address-point slot `+0xb0`. The main-thread pump must remain active while resume is pending.
- Controller removal is immediate, but old-controller destruction can be deferred. `clearSessionController(..., true)` submits a `SessionCleanUpTask` holding the removed controller; final `Streamer` destruction calls `Streamer::stop(false)` before releasing its connection and configuration resources. Old and new streamers can therefore coexist briefly, but only the new controller remains publicly addressable and their endpoint storage is separate.
- Bifrost contains a private internal-event case that calls `SessionController::doResume()` and resubmits action `2` on the existing controller. Neither architecture has a proven producer for that internal event, Geronimo does not act on the corresponding server pause/resume session-notification values, and no exported API can safely inject it. This path must remain unsupported unless a live session proves it reachable.
- No exported API performs in-place endpoint mutation or authoritative endpoint readback. None of the `0x00...0x1a` feature-control cases changes endpoint configuration, starts or stops a streamer, or triggers resume. Same-session public resume is the only verified endpoint-refresh mechanism, and endpoint selection remains controlled by returned `SessionInfo.connectionInfo`.

## Verified Packet-Size Facts

- `NVbVideoSettings_t` is `0x160` bytes and stores its requested packet size as a `uint16_t` at `+0x38`.
- `Nsk::convertToStreamingParams` maps that value to `NVbStreamSettings_t + 0x48`; the value is measured in bytes.
- Bifrost treats configured values below `512` bytes as invalid and replaces them with `512`.
- Geronimo/Bifrost deep-copies every `0x170`-byte `NVbStreamSettings_t` during startup. OpenNOW may therefore apply a server-measured packet size to the converted settings before `GridApp::start` or `GridApp::resume`.
- No exported feature-control case changes packet size at runtime. Internal packet-size detection, `ServerControl::sendPacketSizeChangeRequest`, and `ClientStatsTool::setAllowedPacketSizeDetectionParams` require inaccessible session-owned objects and provide no application callback or authoritative readback.
- Runtime interface-change handling updates connection type but does not restart packet-size negotiation. Runtime packet-size adaptation must remain Bifrost-owned.

## Verified Native Network Capability Test Boundary

- `_nvbTestNetworkCapabilityAsync` accepts an 88-byte parameter block and starts a self-owned asynchronous UDP capability test. It deep-copies the server address and ordered six-byte `{uint16_t width, uint16_t height, uint16_t framesPerSecond}` profile records.
- The native tester treats `serverAddress` as a bare DNS name or IP address and always connects to UDP port `5001`. It does not perform HTTP provisioning, parse `/v2/nettestsession`, consume credentials, or accept a port.
- The returned 20-byte result contains a status code at `+0x00` and cancellation request id at `+0x04`. `_nvbTestNetworkAsyncCancel(uint32_t)` consumes that request id.
- The completion callback receives callback-scoped capability data and a generated network-session GUID; both must be copied before the callback returns.
- NVIDIA's unavailable `CrimsonNative/NetworkTest` dispatcher performs additional authenticated provisioning and maps the high-level zone response to the low-level UDP host before invoking this ABI. The browser `/v2/nettestsession` connection endpoint is HTTP/WebRTC and is not evidence of an NT2 UDP host on port `5001`.
- OpenNOW must not call `_nvbTestNetworkCapabilityAsync` until the provisioned UDP host and all native threshold mappings are present in an observed dispatcher contract. Passing the known HTTP endpoint would target the wrong protocol.

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
- Decoder creation and initialization receive the requested or setup-negotiated NVB codec enum unchanged: H.264 is `1`, HEVC is `2`, and AV1 is `4`. Setup success remains authoritative and recreates a decoder when its negotiated enum differs from the setup-time request.
- Verified native presentation claims are codec-specific. H.264 remains 8-bit SDR, HEVC may claim 10-bit HDR only with hardware HEVC decode and EDR on the actual stream window screen, and AV1 may claim verified 10-bit decode but not HDR. AV1 HDR remains disabled because the binary additionally gates it on unresolved remote settings and macOS-version policy.
- The AppKit proxy and reparented `CAMetalLayer` opt into extended dynamic range only for a negotiated supported HDR presentation. HDR does not force an sRGB proxy color space or replace the vendor layer's pixel format/color space; SDR and loss of screen EDR restore the sRGB presentation fallback.
- `OpenNOWNativeNVSTGeronimoSetVideoSurface(session, nativeHandle, ...)` stores the OpenNOW proxy `NSWindow` handle before window construction and emits native phase `22`.
- Exported audio symbols include `platformCreateAudioCapturer`, `platformCreateAudioRenderer`, `IOInterface::registerAudioCallback`, `IOInterface::registerAudioCaptureCallback`, `GridApp::sendMicAudioFrame`, `SDLAudio::renderAudio`, and `WebRTCAudioCapturer::*`; OpenNOW has no exported `GridApp` API to retrieve the active `IOInterface *` required for callback registration.
- `SDLAudio::renderAudio` reads the incoming `NvstAudioFrame_t` channel count at `+0x10`. When it differs from the renderer state at `SDLAudio + 0x1a8`, the vendor implementation stores the incoming count, closes the SDL audio device, refreshes default-device information, resizes its queue, and calls `openSDLSource` again. OpenNOW therefore leaves `SessionParameters +0x233` at the vendor stereo baseline instead of forcing requested 5.1/7.1 bytes; incoming 6- and 8-channel frames drive the verified reopen path.
- A non-disabled microphone mode creates the Geronimo audio capturer even when it starts muted. `WebRTCAudioCapturer` address-point slots `+0x40` and `+0x48` pause and resume capture; `OpenNOWNativeNVSTGeronimoSetMicrophoneEnabled` invokes those slots on the main thread while streaming, matching the existing streaming-begin lifecycle.
- Geronimo imports `_nvbSendMicAudioFrame` through a lazy symbol pointer. Its arm64 call contract uses `x8` for the `0x14`-byte `NVbResult_t` result storage, `x0` for the Bifrost client, `x1` for the session identifier, and `x2` for the indirect by-value `NvstAudioFrame_t`. Geronimo copies exactly `0x58` frame bytes before the call.
- The verified canonical microphone descriptor has bits per sample `16` at `+0x08`, sample rate `48000` at `+0x0c`, channel count `2` at `+0x10`, format `4` at `+0x14`, PCM pointer at `+0x28`, and PCM byte count `1920` at `+0x30`. This is 480 interleaved stereo samples, or 10 ms. OpenNOW never processes any other descriptor.
- The production hook discovers the loaded Geronimo lazy pointer by bounded parsing of `LC_SEGMENT_64`, `LC_SYMTAB`, and `LC_DYSYMTAB`, including `S_LAZY_SYMBOL_POINTERS` indirect-symbol entries. No production address or file offset is fixed. Installation requires a non-null verified import slot; the original callable target is resolved independently with `dlsym("nvbSendMicAudioFrame")`, so dyld's valid lazy-binding targets do not fail pointer-identity checks.
- Hook ownership is process-global and leased by initialized `GridApp` sessions. The pointer is installed and restored with atomic compare-exchange. Fixed process-global route slots key each call by the Bifrost client stored at `GridApp +0x18`; route removal rejects new acquisitions and drains in-flight calls before teardown releases the hook lease or destroys the client.
- Supported frames are copied into thread-local descriptor and PCM storage. OpenNOW changes only the copied PCM pointer, preserving every descriptor field, side-data pointer, timestamp, and release field. Unsupported frames call the original import unchanged. VAD silence is forwarded as a full zeroed frame rather than dropped.
- Microphone volume is clamped to `0...1`, applied with bounded signed-16-bit arithmetic, and cannot amplify or wrap. Voice activity uses deterministic normalized RMS, an adaptive non-speech noise floor, a two-frame attack, and a 20-frame hangover. Disabling VAD or capture, pausing, stopping, recovery teardown, and route destruction reset the adaptive state.
- Settings semantics are explicit: `disabled` does not request capture, `push-to-talk` creates capture paused with VAD disabled, and `voice-activity` creates capture running with VAD enabled. Runtime setters update volume and VAD without changing the capturer pause/resume state.
- libGeronimo exposes native stream-provider recording primitives, but OpenNOW's base `GridApp` session has no registered `IStreamRecorder` sink or file writer. Native NVST therefore reports recording as unavailable instead of swallowing `⌘R` or pretending a recording started.
- `GridApp::sendNvstInputEvent(NvstInputEvent_t const&)` is exported and is the safest input-send entry point. `NvstInputEvent_t` is copied as exactly `0x48` bytes, with event type at offset `0x00`.
- Swift `NativeNVSTInputEncoder` emits the verified native `NvstInputEvent_t` representation directly for keyboard, relative mouse, wheel, button, and gamepad input. Absolute mouse events are constructed by the native shim after vendor coordinate conversion. Every non-text event is exactly `0x48` bytes and is sent synchronously through `GridApp::sendNvstInputEvent`.
- Keyboard event type `1` stores the mapped Darwin key value at `+0x08`, modifiers at `+0x0e`, action `1`/`2` for release/press at `+0x10`, and the microsecond timestamp at `+0x18`.
- Caps-lock event type `15` stores state `1`/`2` for off/on at `+0x08`.
- Mouse event type `2` stores subtype at `+0x08`: movement subtype `1` uses signed deltas at `+0x10/+0x14`, wheel subtype `2` uses signed detents at `+0x24`, and button subtype `3` uses button id at `+0x18` and action at `+0x1c`. Mouse timestamps are at `+0x28`.
- Gamepad event type `18` stores signed 16-bit controls from `+0x08`, source index at `+0x3e`, and microsecond timestamp at `+0x40`. OpenNOW registers each source once through `GridApp::handleGamepadChanged` before sending its first event.
- Text event type `20` stores a borrowed UTF-8 pointer at `+0x08` and a 16-bit byte count at `+0x10`. The shim constructs and sends this event synchronously so the borrowed pointer cannot escape its Swift `Data` lifetime.
- Native Geronimo input does not use OpenNOW's WebRTC data-channel envelope or partially reliable transfer flags.
- Direct `_nvbSendInputEvent` requires the underlying Bifrost client handle, session id, and `NVbResult_t` sret ABI and should not be called from Swift or from a shim that does not own those values.

## Verified Mouse/Cursor Host Facts

- NVST has separate absolute client-cursor and relative locked modes. Absolute movement uses mouse subtype `1`, flag `0x0800` at `NvstMouseEvent_t + 0x0c`, signed 32-bit rendered-frame logical coordinates at `+0x10/+0x14`, nonzero rendered-frame reference width and height at `+0x18/+0x1c`, and the microsecond timestamp at `+0x28`. Relative movement uses the same subtype with flags `0` and signed deltas at `+0x10/+0x14`.
- `GridApp::onCursorInfoUpdate(CursorInfo const&)` is the verified vtable slot at address-point offset `0x118`. OpenNOW calls NVIDIA's original handler before observing cursor state `1` as visible/client-side and state `2` as hidden/relative. Startup verifies the slot against the exact exported symbol and fails closed if the vendor ABI changes.
- Visible server cursor state selects unlocked absolute input. AppKit positions are converted into the native SDL window's top-left-origin logical coordinates, then the shim calls the exported `SDLWindow::convertPointToVideoFrame` for NVIDIA's exact live decoded-aspect, viewport, resize, clamping, and reference-extent behavior. Positions in letterbox or pillarbox regions clamp to the nearest rendered-frame edge, matching the vendor converter and ensuring each button edge has a current remote position. Geronimo remains responsible for applying server-provided system and bitmap cursor images to the local hardware cursor.
- Hidden server cursor state selects relative input when Direct Mouse Input is enabled. Pointer lock stores the pre-capture global cursor position, dissociates physical mouse movement from the macOS cursor, hides the local cursor, and consumes AppKit movement, drag, and wheel events through one local monitor. Unlock reverses those steps and restores the saved cursor position.
- WebRTC retains click-to-capture behavior. NVST starts unlocked and follows server cursor state, so desktop launchers do not lose their first click and games can transition into relative control without displaying a duplicate stationary cursor.
- Pointer unlock occurs when remote input or direct mouse input is disabled, the application or stream window loses focus, the interactive HUD opens, the stream view detaches, or stream teardown begins. Held mouse buttons are released before pointer lock is cleared so the release events pass the same lock gate as normal mouse input.
- OpenNOW captures keyboard events only when their target is the stream window, then consumes its explicit stream commands and remote paste shortcut before forwarding input. WebRTC and NVST share one shortcut resolver: `⌘G` HUD, `⌘M` microphone, `⌘R` recording, `⌘K` Anti-AFK, `⌘Q` stream controls, and `⌘N` stats. Menu-panel events and other Command-modified key equivalents remain local so AppKit menus and standard window commands continue to work during a stream; a key pressed remotely before becoming Command-modified is released before local routing.
- Native NVST relative movement, absolute movement, wheel input, and button edges use one ordered dispatcher. Absolute mode emits the current position immediately before each button edge because NVST button packets act on the last transmitted cursor position. Events cannot overtake each other, and queued releases are drained before a locally initiated native session stop.

## Verified Performance Stats Facts

- `IOInterface::getStatsInterface()` returns the session-owned `StatsInterface *`. `StatsInterface::getStats(...)` locks its internal state, copies a `0x450`-byte `GeronimoStats` value, and copies GPU, renderer, client-version, locale, region, and zone strings into caller-owned `std::string` values.
- The copied stats store total frame loss at `+0x08`, jitter in microseconds at `+0x24`, bitrate in Kbps at `+0xa0`, bandwidth utilization at `+0xa4`, current packet loss at `+0xa8`, and round-trip delay in milliseconds at `+0xac`.
- Codec is at `+0x3bc`; initial width, height, and FPS are at `+0x3e4/+0x3e6/+0x3e8`; current width and height are at `+0x3ea/+0x3ec`; current frame loss and total packet loss are at `+0x3f0/+0x3f4`; server game FPS is a `double` at `+0x410`.
- `OpenNOWNativeNVSTGeronimoCopyPerformanceStats` reads this synchronized state while the session is streaming and returns only normalized scalar values plus the zone or region string. It does not expose the opaque native stats object to Swift.
- `Cmd+N` toggles OpenNOW's SwiftUI GFN-style panel and never calls Geronimo's internal performance indicator, which is restricted for external users and may render nothing.

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
- `OpenNOWNativeNVSTGeronimoPump` must run on the main thread for the lifetime of the session. Its integer argument is the `SDL_WaitEventTimeout` duration in milliseconds; `0` performs nonblocking SDL polling. A false `SDLEventProcessor::processEvents` result is terminal.
- The vendor main loop dispatches `GridApp::processEvents()` before SDL processing and services SDL at render-loop cadence with a maximum 16 ms wait. OpenNOW preserves that order and uses a nonblocking 60 Hz timer in the default AppKit run-loop mode. The timer therefore yields completely during title-bar, menu, and other event-tracking loops instead of competing with AppKit for input delivery.
- Swift keeps the main-thread pump active while waiting for asynchronous pause and stop callbacks. It invalidates the timer before destroying the native session.
- A successful pause destroys local media and GridApp resources without calling `GridApp::stop`, preserving the intentionally paused cloud session for a later resume allocation.
- Normal disconnect calls `GridApp::stop(char const *, int)`, waits for slot `+0x158`, then invalidates the pump timer and destroys the session. Remote termination skips this stop wait because the vendor session is already stopped.
- `GridAppD2` calls `GridApp::uninitialize()` internally. OpenNOW must not call uninitialize a second time, and it keeps the process platform and both dylib handles alive until the destructor returns.
- Destruction restores the embedded Metal view to the retained proxy window, detaches the per-session callback owner and waits for in-flight callbacks, destroys shim-owned media, runs `GridAppD2`, releases the video surface and reference-counted process platform, frees the cloned vtable, and closes the dylib handles.
