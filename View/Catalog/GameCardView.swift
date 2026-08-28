import SwiftUI

struct GameCardView: View {
    private static let cardWidth: CGFloat = 198
    private static let cardHeight: CGFloat = 118

    let game: CatalogGameObject
    let isSelected: Bool
    let select: () -> Void
    let launch: () -> Void

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottom) {
                CatalogRemoteImage(url: URL(string: game.bestTileImageURL), contentMode: .fill)
                    .frame(width: Self.cardWidth, height: Self.cardHeight)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.90)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                Text(game.title.isEmpty ? "Untitled game" : game.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .black, radius: 4)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                    .frame(width: Self.cardWidth)
            }
            .frame(width: Self.cardWidth, height: Self.cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .modifier(CardPulseModifier(isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: launch)
        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: isSelected)
        .accessibilityLabel(game.title.isEmpty ? "Untitled game" : game.title)
        .accessibilityHint("Click to select. Double-click to launch.")
    }
}

private struct CardPulseModifier: ViewModifier {
    let isSelected: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.18), lineWidth: isSelected ? (isPulsing ? 4 : 2) : 1)
            }
            .shadow(color: isSelected ? Color.accentColor.opacity(isPulsing ? 1.0 : 0.4) : .clear, radius: isSelected ? (isPulsing ? 20 : 8) : 0)
            .scaleEffect(isSelected ? (isPulsing ? 1.05 : 1.02) : 1.0)
            .animation(isSelected ? .easeInOut(duration: 1.2).repeatForever(autoreverses: true) : .interactiveSpring(response: 0.24, dampingFraction: 0.86), value: isPulsing)
            .onAppear {
                if isSelected { isPulsing = true }
            }
            .onChange(of: isSelected) { _, selected in
                isPulsing = selected
            }
    }
}
