import SwiftUI

enum OpenNOWDesign {
    enum Surface {
        static let app = Color(red: 8 / 255, green: 18 / 255, blue: 29 / 255)
        static let appBar = Color(red: 5 / 255, green: 12 / 255, blue: 20 / 255)
        static let panel = Color(red: 12 / 255, green: 25 / 255, blue: 38 / 255)
        static let panelRaised = Color(red: 17 / 255, green: 34 / 255, blue: 48 / 255)
        static let tileTray = Color(red: 21 / 255, green: 39 / 255, blue: 52 / 255)
        static let field = Color(red: 11 / 255, green: 22 / 255, blue: 33 / 255)
        static let scrim = Color.black.opacity(0.58)
    }

    enum Text {
        static let primary = Color.white.opacity(0.96)
        static let secondary = Color.white.opacity(0.68)
        static let tertiary = Color.white.opacity(0.48)
        static let muted = Color.white.opacity(0.38)
    }

    enum Stroke {
        static let subtle = Color.white.opacity(0.08)
        static let regular = Color.white.opacity(0.12)
        static let strong = Color.white.opacity(0.20)
    }

    enum Spacing {
        static let pageHorizontal: CGFloat = 32
        static let railHorizontal: CGFloat = 16
        static let card: CGFloat = 14
    }

    enum Radius {
        static let avatar: CGFloat = 12
    }

    static let accent = Color.openNowGreen

    static func clamped(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

extension View {
    func openNowFocusRing(_ isFocused: Bool) -> some View {
        overlay {
            Rectangle()
                .stroke(isFocused ? Color.openNowGreen : .clear, lineWidth: 2)
        }
    }
}
