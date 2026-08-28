import SwiftUI

struct GameDetailOverlayPanel: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject?
    let play: () -> Void
    let toggleFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(game?.title ?? "")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 54, alignment: .bottom)

            HStack(spacing: 14) {
                if let dev = game?.developerName, !dev.isEmpty {
                    Label(dev, systemImage: "person.crop.circle")
                }
                if let release = game?.releaseDate, !release.isEmpty {
                    Label(String(release.prefix(4)), systemImage: "calendar")
                }
                if let genres = game?.genres, !genres.isEmpty {
                    Label(genres.prefix(2).joined(separator: ", "), systemImage: "gamecontroller")
                }
                if game?.isFreeToPlay == true {
                    Label("Free", systemImage: "tag")
                }
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.72))
            .lineLimit(1)
            .frame(height: 18)

            let description = game.map { $0.shortDescription.isEmpty ? $0.longDescription : $0.shortDescription } ?? ""
            Text(description)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 620, minHeight: 60, maxHeight: 60, alignment: .top)

            HStack(spacing: 12) {
                let actionText = game?.isLaunchPatching == true ? "Queue" : ((game?.cardPrimaryActionIsLaunchable ?? false) ? "Play" : "Mark Owned")
                Button(actionText, action: play)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(game == nil)
                
                Button(action: toggleFavorite) {
                    Image(systemName: (game != nil && viewModel.isFavorite(game!)) ? "heart.fill" : "heart")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(game == nil)
                .help((game != nil && viewModel.isFavorite(game!)) ? "Remove from favorites" : "Add to favorites")
            }
            .padding(.top, 4)
            .frame(height: 48)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(height: 220)
        .frame(maxWidth: 700)
        .modifier(LiquidGlassModifier(cornerRadius: 22))
        .opacity(game == nil ? 0 : 1)
        .contentTransition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: game?.id)
    }
}
