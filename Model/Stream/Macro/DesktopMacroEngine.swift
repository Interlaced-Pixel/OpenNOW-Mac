import Foundation

public struct DesktopMacroTimings: Equatable, Sendable {
    public var initialDelay: TimeInterval
    public var keystrokeDelay: TimeInterval
    public var navigationDelay: TimeInterval
    public var downloadDelay: TimeInterval

    public init(
        initialDelay: TimeInterval = StreamPreferences.defaultDesktopMacroInitialDelay,
        keystrokeDelay: TimeInterval = StreamPreferences.defaultDesktopMacroKeystrokeDelay,
        navigationDelay: TimeInterval = StreamPreferences.defaultDesktopMacroNavigationDelay,
        downloadDelay: TimeInterval = StreamPreferences.defaultDesktopMacroDownloadDelay
    ) {
        self.initialDelay = initialDelay
        self.keystrokeDelay = keystrokeDelay
        self.navigationDelay = navigationDelay
        self.downloadDelay = downloadDelay
    }
}

public enum DesktopMacroState: Equatable, Sendable {
    case idle
    case waiting(remainingSeconds: Int)
    case openingBrowser
    case enteringURL
    case downloading
    case launchingExecutable
    case completed
    case cancelled
    case failed(String)

    public var displayMessage: String {
        switch self {
        case .idle: return "Desktop Macro: Ready"
        case .waiting(let seconds): return "SalsaNOW: Waiting for Steam (\(seconds)s)..."
        case .openingBrowser: return "SalsaNOW: Opening Steam Browser..."
        case .enteringURL: return "SalsaNOW: Typing SalsaNOW URL..."
        case .downloading: return "SalsaNOW: Downloading SalsaNOW Updater..."
        case .launchingExecutable: return "SalsaNOW: Launching SalsaNOW Desktop Shell..."
        case .completed: return "SalsaNOW Desktop Launched!"
        case .cancelled: return "Desktop Setup Cancelled"
        case .failed(let message): return "Desktop Setup Error: \(message)"
        }
    }
}

public final class DesktopMacroEngine: @unchecked Sendable {
    public static let salsaDownloadURL = "https://salsanowfiles.work/SalsaNOW/SalsaNOWUpdater.exe"

    private let sendEvent: @Sendable (UserInputEvent) -> Void
    private var executionTask: Task<Void, Never>?
    private var isRunning = false

    public init(sendEvent: @escaping @Sendable (UserInputEvent) -> Void) {
        self.sendEvent = sendEvent
    }

    deinit {
        cancel()
    }

    public func cancel() {
        executionTask?.cancel()
        executionTask = nil
        isRunning = false
    }

    public func execute(
        timings: DesktopMacroTimings,
        statusHandler: @escaping @MainActor (DesktopMacroState) -> Void
    ) {
        cancel()
        isRunning = true

        executionTask = Task { [weak self] in
            guard let self else { return }

            await statusHandler(.waiting(remainingSeconds: Int(timings.initialDelay)))

            // 1. Initial wait for GFN / Steam startup
            let totalWaitSeconds = max(1, Int(timings.initialDelay))
            for second in (1...totalWaitSeconds).reversed() {
                guard !Task.isCancelled else {
                    await statusHandler(.cancelled)
                    return
                }
                await statusHandler(.waiting(remainingSeconds: second))
                try? await Task.sleep(for: .seconds(1))
            }

            guard !Task.isCancelled else {
                await statusHandler(.cancelled)
                return
            }

            // 2. Open Steam Web Browser
            await statusHandler(.openingBrowser)

            // Primary method: Shift + Tab (Steam overlay)
            await self.sendKeyCombination(
                modifiers: [(keyCode: 56, scanCode: 0x2a)], // Left Shift
                key: (keyCode: 48, scanCode: 0x0f),        // Tab
                keyDelay: timings.keystrokeDelay
            )
            try? await Task.sleep(for: .seconds(timings.navigationDelay))

            guard !Task.isCancelled else {
                await statusHandler(.cancelled)
                return
            }

            // Focus Browser Address Bar: Ctrl + L
            await self.sendKeyCombination(
                modifiers: [(keyCode: 59, scanCode: 0x1d)], // Left Control
                key: (keyCode: 37, scanCode: 0x26),        // L
                keyDelay: timings.keystrokeDelay
            )
            try? await Task.sleep(for: .seconds(timings.keystrokeDelay))

            // Focus and clear address bar with Backspace
            await self.sendKeyPress(keyCode: 51, scanCode: 0x0e, delay: timings.keystrokeDelay) // Backspace

            // 3. Enter URL
            await statusHandler(.enteringURL)
            self.sendText(Self.salsaDownloadURL)
            try? await Task.sleep(for: .seconds(timings.keystrokeDelay * 2))

            // Press Enter to navigate/download
            await self.sendKeyPress(keyCode: 36, scanCode: 0x1c, delay: timings.keystrokeDelay) // Return / Enter

            // 4. Wait for download to finish
            await statusHandler(.downloading)
            try? await Task.sleep(for: .seconds(timings.downloadDelay))

            guard !Task.isCancelled else {
                await statusHandler(.cancelled)
                return
            }

            // 5. Open Downloaded File / Launch Executable
            await statusHandler(.launchingExecutable)

            // In Steam / Chromium browser, press Ctrl + J (Downloads)
            await self.sendKeyCombination(
                modifiers: [(keyCode: 59, scanCode: 0x1d)], // Left Control
                key: (keyCode: 38, scanCode: 0x24),        // J
                keyDelay: timings.keystrokeDelay
            )
            try? await Task.sleep(for: .seconds(timings.navigationDelay))

            // Press Enter / Tab + Enter to execute the downloaded file
            await self.sendKeyPress(keyCode: 48, scanCode: 0x0f, delay: timings.keystrokeDelay) // Tab
            try? await Task.sleep(for: .seconds(timings.keystrokeDelay))
            await self.sendKeyPress(keyCode: 36, scanCode: 0x1c, delay: timings.keystrokeDelay) // Enter

            // Also send Return again after brief pause for security/run prompt if any
            try? await Task.sleep(for: .seconds(0.5))
            await self.sendKeyPress(keyCode: 36, scanCode: 0x1c, delay: timings.keystrokeDelay) // Enter

            // Close overlay: Shift + Tab or Escape
            try? await Task.sleep(for: .seconds(0.5))
            await self.sendKeyPress(keyCode: 53, scanCode: 0x01, delay: timings.keystrokeDelay) // Escape

            await statusHandler(.completed)
            self.isRunning = false
        }
    }

    private static func currentTimestamp() -> MediaTimestamp {
        MediaTimestamp(nanoseconds: DispatchTime.now().uptimeNanoseconds)
    }

    private func sendKeyPress(keyCode: UInt16, scanCode: UInt16, delay: TimeInterval) async {
        let timestamp = Self.currentTimestamp()
        let down = KeyboardEvent(
            deviceID: "keyboard",
            keyCode: keyCode,
            scanCode: scanCode,
            modifiers: [],
            isPressed: true,
            timestamp: timestamp
        )
        sendEvent(.keyboard(down))

        try? await Task.sleep(for: .milliseconds(max(20, Int(delay * 1000))))

        let up = KeyboardEvent(
            deviceID: "keyboard",
            keyCode: keyCode,
            scanCode: scanCode,
            modifiers: [],
            isPressed: false,
            timestamp: Self.currentTimestamp()
        )
        sendEvent(.keyboard(up))
    }

    private func sendKeyCombination(
        modifiers: [(keyCode: UInt16, scanCode: UInt16)],
        key: (keyCode: UInt16, scanCode: UInt16),
        keyDelay: TimeInterval
    ) async {
        let timestamp = Self.currentTimestamp()
        for mod in modifiers {
            let modDown = KeyboardEvent(
                deviceID: "keyboard",
                keyCode: mod.keyCode,
                scanCode: mod.scanCode,
                modifiers: [],
                isPressed: true,
                timestamp: timestamp
            )
            sendEvent(.keyboard(modDown))
        }

        try? await Task.sleep(for: .milliseconds(30))

        let keyDown = KeyboardEvent(
            deviceID: "keyboard",
            keyCode: key.keyCode,
            scanCode: key.scanCode,
            modifiers: [],
            isPressed: true,
            timestamp: Self.currentTimestamp()
        )
        sendEvent(.keyboard(keyDown))

        try? await Task.sleep(for: .milliseconds(max(30, Int(keyDelay * 1000))))

        let keyUp = KeyboardEvent(
            deviceID: "keyboard",
            keyCode: key.keyCode,
            scanCode: key.scanCode,
            modifiers: [],
            isPressed: false,
            timestamp: Self.currentTimestamp()
        )
        sendEvent(.keyboard(keyUp))

        try? await Task.sleep(for: .milliseconds(20))

        for mod in modifiers.reversed() {
            let modUp = KeyboardEvent(
                deviceID: "keyboard",
                keyCode: mod.keyCode,
                scanCode: mod.scanCode,
                modifiers: [],
                isPressed: false,
                timestamp: Self.currentTimestamp()
            )
            sendEvent(.keyboard(modUp))
        }
    }

    private func sendText(_ text: String) {
        sendEvent(.text(deviceID: "keyboard", value: text, timestamp: Self.currentTimestamp()))
    }
}
