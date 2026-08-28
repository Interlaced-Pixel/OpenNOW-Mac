import SwiftUI

struct LibraryGridView: View {
    @ObservedObject var viewModel: CatalogViewModel
    @ObservedObject var store: CatalogSelectionStore
    let play: (CatalogGameObject) -> Void

    let columns = [GridItem(.adaptive(minimum: 200), spacing: 24)]

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 24) {
                    ForEach(Array(store.games.enumerated()), id: \.element.id) { index, game in
                        GameCardView(
                            game: game,
                            isSelected: index == store.selectedIndex,
                            select: { store.select(at: index) },
                            launch: { play(game) }
                        )
                        .id(CatalogSelectionStore.gameIdentity(game))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 120)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: .infinity)

            LibrarySidePanel(
                viewModel: viewModel,
                game: store.selectedGame,
                play: { if let g = store.selectedGame { play(g) } },
                toggleFavorite: {
                    if let g = store.selectedGame {
                        viewModel.selectGame(g)
                        viewModel.toggleFavoriteSelectedGame()
                    }
                }
            )
            .frame(width: 380)
            .background(.black.opacity(0.4))
            .background(.ultraThinMaterial)
        }
        .ignoresSafeArea()
    }
}

private struct LibrarySidePanel: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject?
    let play: () -> Void
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let game = game {
                CatalogRemoteImage(url: URL(string: game.imageUrl), contentMode: .fill)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 8)

                Text(game.title.isEmpty ? "Untitled game" : game.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 10) {
                    if !game.developerName.isEmpty {
                        Label(game.developerName, systemImage: "person.crop.circle")
                    }
                    if !game.releaseDate.isEmpty {
                        Label(String(game.releaseDate.prefix(4)), systemImage: "calendar")
                    }
                    if !game.genres.isEmpty {
                        Label(game.genres.prefix(2).joined(separator: ", "), systemImage: "gamecontroller")
                    }
                    if game.isFreeToPlay {
                        Label("Free", systemImage: "tag")
                    }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))

                let description = game.shortDescription.isEmpty ? game.longDescription : game.shortDescription
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(8)

                Spacer()

                VStack(spacing: 12) {
                    let actionText = game.isLaunchPatching ? "Queue"
                        : (game.cardPrimaryActionIsLaunchable ? "Play" : "Mark Owned")
                    Button(actionText, action: play)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                    Button(action: toggleFavorite) {
                        Label(viewModel.isFavorite(game) ? "Remove Favorite" : "Add to Favorites",
                              systemImage: viewModel.isFavorite(game) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            } else {
                Spacer()
                Text("Select a game to view details")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .padding(24)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: game?.id)
    }
}
