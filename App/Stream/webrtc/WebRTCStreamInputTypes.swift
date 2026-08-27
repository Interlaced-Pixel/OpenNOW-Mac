import AppKit

public enum WebRTCMediaStreamCommand: Equatable, Sendable {
    case toggleStatsHUD
    case toggleUnifiedHUD
    case toggleMicrophone
    case toggleRecording
    case toggleAntiAFK
    case showQuitMenu

    static let shortcutGuide = "⌘G HUD   ⌘N Stats   ⌘M Mic   ⌘R Rec   ⌘K AFK   ⌘Q Quit"

    static func shortcutCommand(keyCode: UInt16, modifierFlags: NSEvent.ModifierFlags) -> WebRTCMediaStreamCommand? {
        let modifiers = modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.capsLock, .numericPad])
        guard modifiers == .command else { return nil }
        switch keyCode {
        case 46: return .toggleMicrophone
        case 15: return .toggleRecording
        case 40: return .toggleAntiAFK
        case 45: return .toggleStatsHUD
        case 5: return .toggleUnifiedHUD
        case 12: return .showQuitMenu
        default: return nil
        }
    }
}

public enum WebRTCStreamMouseInputMode: Equatable, Sendable {
    case absolute
    case relative
}

struct WebRTCStreamTextInputState {
    private(set) var markedText = NSAttributedString()
    private(set) var selection = NSRange(location: 0, length: 0)

    var hasMarkedText: Bool { markedText.length > 0 }
    var markedRange: NSRange { hasMarkedText ? NSRange(location: 0, length: markedText.length) : NSRange(location: NSNotFound, length: 0) }

    mutating func setMarkedText(_ text: NSAttributedString, selectedRange: NSRange, replacementRange: NSRange) {
        if replacementRange.location != NSNotFound,
           NSMaxRange(replacementRange) <= markedText.length {
            let mutableText = NSMutableAttributedString(attributedString: markedText)
            mutableText.replaceCharacters(in: replacementRange, with: text)
            markedText = mutableText
        } else {
            markedText = text
        }
        selection = Self.clamped(selectedRange, length: markedText.length)
    }

    mutating func commit(_ text: String) -> String? {
        markedText = NSAttributedString()
        selection = NSRange(location: 0, length: 0)
        return text.isEmpty ? nil : text
    }

    mutating func unmark() -> String? {
        commit(markedText.string)
    }

    mutating func cancel() {
        markedText = NSAttributedString()
        selection = NSRange(location: 0, length: 0)
    }

    func attributedSubstring(for range: NSRange) -> (NSAttributedString, NSRange)? {
        guard hasMarkedText, range.location != NSNotFound else { return nil }
        let intersection = NSIntersectionRange(range, markedRange)
        guard intersection.length > 0 else { return nil }
        return (markedText.attributedSubstring(from: intersection), intersection)
    }

    private static func clamped(_ range: NSRange, length: Int) -> NSRange {
        guard range.location != NSNotFound else { return NSRange(location: length, length: 0) }
        let location = min(range.location, length)
        return NSRange(location: location, length: min(range.length, length - location))
    }
}

final class WebRTCStreamPushToTalkState {
    private let keyCode: UInt16
    private let modifierMask: UInt16
    private var onChange: (Bool) -> Void
    private(set) var isPressed = false

    init(keyCode: Int, modifierMask: Int, onChange: @escaping (Bool) -> Void) {
        self.keyCode = UInt16(clamping: keyCode)
        self.modifierMask = UInt16(truncatingIfNeeded: modifierMask) & Self.supportedModifiers
        self.onChange = onChange
    }

    func handle(_ event: KeyboardEvent) -> Bool {
        guard event.keyCode == keyCode else { return false }
        if event.isPressed {
            guard event.modifiers.rawValue & Self.supportedModifiers == modifierMask else { return false }
            guard !isPressed else { return true }
            isPressed = true
            onChange(true)
            return true
        }
        guard isPressed else { return false }
        isPressed = false
        onChange(false)
        return true
    }

    func release() {
        guard isPressed else { return }
        isPressed = false
        onChange(false)
    }

    func update(keyCode: Int, modifierMask: Int, onChange: @escaping (Bool) -> Void) -> Bool {
        let normalizedKeyCode = UInt16(clamping: keyCode)
        let normalizedModifierMask = UInt16(truncatingIfNeeded: modifierMask) & Self.supportedModifiers
        guard self.keyCode == normalizedKeyCode, self.modifierMask == normalizedModifierMask else { return false }
        self.onChange = onChange
        return true
    }

    private static let supportedModifiers = KeyboardModifiers.shift.rawValue |
        KeyboardModifiers.control.rawValue | KeyboardModifiers.option.rawValue |
        KeyboardModifiers.command.rawValue | KeyboardModifiers.capsLock.rawValue
}


public struct WebRTCAbsoluteMouseEvent: Equatable, Sendable {
    public let x: Int32
    public let y: Int32
    public let timestamp: MediaTimestamp

    public init(x: Int32, y: Int32, timestamp: MediaTimestamp) {
        self.x = x
        self.y = y
        self.timestamp = timestamp
    }
}

public struct WebRTCHapticCommand: Equatable, Sendable {
    public let playerIndex: Int
    public let lowFrequency: UInt16
    public let highFrequency: UInt16
    public let durationMilliseconds: UInt16

    public init(playerIndex: Int, lowFrequency: UInt16, highFrequency: UInt16, durationMilliseconds: UInt16) {
        self.playerIndex = playerIndex
        self.lowFrequency = lowFrequency
        self.highFrequency = highFrequency
        self.durationMilliseconds = durationMilliseconds
    }
}
