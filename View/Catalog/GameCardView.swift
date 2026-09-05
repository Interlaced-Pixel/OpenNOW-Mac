import SwiftUI

struct GameCardView: View {
    let game: CatalogGameObject
    let isSelected: Bool
    var scale: CGFloat = 1.0
    let select: () -> Void
    let launch: () -> Void

    var isFavorite: Bool = false
    var onToggleFavorite: (() -> Void)? = nil
    var onSelectPlatform: ((Int) -> Void)? = nil
    var onAddShortcut: (() -> Void)? = nil
    var onOpenStore: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil

    @State private var isLaunchSettingsPresented = false

    private var cardWidth: CGFloat { 138 * scale }
    private var cardHeight: CGFloat { 207 * scale }

    var body: some View {
        Button(action: select) {
            ZStack(alignment: .bottom) {
                CatalogRemoteImage(url: URL(string: game.bestStorePickerPosterURL), contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
            }
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12 * scale, style: .continuous))
            .modifier(CardPulseModifier(isSelected: isSelected, scale: scale))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: launch)
        .contextMenu {
            GameCardContextMenuContent(
                game: game,
                isFavorite: isFavorite,
                onPlay: launch,
                onSelectPlatform: { idx in onSelectPlatform?(idx) },
                onToggleFavorite: { onToggleFavorite?() },
                onOpenSettings: {
                    if let onOpenSettings {
                        onOpenSettings()
                    } else {
                        isLaunchSettingsPresented = true
                    }
                },
                onAddShortcut: { onAddShortcut?() },
                onOpenStore: { onOpenStore?() }
            )
        }
        .sheet(isPresented: $isLaunchSettingsPresented) {
            GameLaunchSettingsSheet(game: game) {
                isLaunchSettingsPresented = false
            }
        }
        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: isSelected)
        .accessibilityLabel(game.title.isEmpty ? "Untitled game" : game.title)
        .accessibilityHint("Click to select. Double-click to launch. Right-click for game options.")
    }
}

private struct CardPulseModifier: ViewModifier {
    let isSelected: Bool
    var scale: CGFloat = 1.0
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: 12 * scale, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.18), lineWidth: isSelected ? (isPulsing ? 4 * scale : 2 * scale) : 1 * scale)
            }
            .shadow(color: isSelected ? Color.accentColor.opacity(isPulsing ? 1.0 : 0.4) : .clear, radius: isSelected ? (isPulsing ? 20 * scale : 8 * scale) : 0)
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
