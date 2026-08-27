import SwiftUI

enum Design {
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
        static let card: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Catalog {
        static let canvas = Color(red: 11 / 255, green: 12 / 255, blue: 16 / 255)
        static let content = Color(red: 14 / 255, green: 16 / 255, blue: 22 / 255)
        static let sidebar = Color(red: 8 / 255, green: 9 / 255, blue: 13 / 255)
        static let inspector = Color(red: 17 / 255, green: 19 / 255, blue: 26 / 255)
        static let elevated = Color(red: 24 / 255, green: 28 / 255, blue: 36 / 255)
        static let selection = Color(red: 138 / 255, green: 92 / 255, blue: 255 / 255)
        static let selectionFill = selection.opacity(0.14)
        static let selectionStroke = selection.opacity(0.62)
        static let action = Color(red: 118 / 255, green: 210 / 255, blue: 28 / 255)
        static let ready = Color(red: 76 / 255, green: 201 / 255, blue: 89 / 255)
        static let warning = Color(red: 232 / 255, green: 148 / 255, blue: 58 / 255)
        static let brand = Color(red: 118 / 255, green: 230 / 255, blue: 26 / 255)
    }

    static let accent = Color.pixelNowGreen

    static func clamped(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

extension View {
    func pixelNowFocusRing(_ isFocused: Bool) -> some View {
        overlay {
            Rectangle()
                .stroke(isFocused ? Color.pixelNowGreen : .clear, lineWidth: 2)
        }
    }

    func catalogFocusRing(_ isFocused: Bool, cornerRadius: CGFloat = 12) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(isFocused ? Design.Catalog.selectionStroke : .clear, lineWidth: 2)
        }
    }
}
