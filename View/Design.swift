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
        static let action = Color.pixelNowBlue
        static let ready = Color(red: 0.15, green: 0.75, blue: 0.98)
        static let warning = Color(red: 232 / 255, green: 148 / 255, blue: 58 / 255)
        static let brand = Color.pixelNowBlue
    }

    enum Glass {
        static let panelCornerRadius: CGFloat = 16
        static let panelStroke = Color.white.opacity(0.15)
        static let hoverStroke = Color.white.opacity(0.40)
        static let panelShadowRadius: CGFloat = 10
        static let panelShadowOpacity: Double = 0.30
    }

    static let accent = Color.pixelNowBlue

    static func clamped(_ value: CGFloat, minimum: CGFloat, maximum: CGFloat) -> CGFloat {
        min(max(value, minimum), maximum)
    }
}

private struct GlassmorphismPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.black.opacity(0.15))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Design.Glass.panelCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Design.Glass.panelCornerRadius, style: .continuous)
                    .stroke(Design.Glass.panelStroke, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(Design.Glass.panelShadowOpacity), radius: Design.Glass.panelShadowRadius, x: 0, y: 5)
    }
}

private struct GlassHoverEffect: ViewModifier {
    let isHovered: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: Design.Glass.panelCornerRadius, style: .continuous)
                    .stroke(isHovered ? Design.Glass.hoverStroke : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: isHovered)
    }
}

extension View {
    func glassmorphismPanel() -> some View {
        modifier(GlassmorphismPanel())
    }

    func glassHoverEffect(isHovered: Bool) -> some View {
        modifier(GlassHoverEffect(isHovered: isHovered))
    }

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
