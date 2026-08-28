import SwiftUI

struct HybridCatalogView: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    private var games: [CatalogGameObject] {
        var result: [CatalogGameObject] = []
        var identities = Set<String>()
        for game in viewModel.catalogSections.flatMap(\.games) {
            let identity = gameIdentity(game)
            guard identities.insert(identity).inserted else { continue }
            result.append(game)
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            navigationBar
            Divider()

            if viewModel.selectedMainPage == .recordings {
                RecordingsView()
            } else if viewModel.selectedMainPage == .settings {
                SettingsView(
                    viewModel: viewModel,
                    accounts: accounts,
                    onSwitch: onSwitch,
                    onAddAccount: onAddAccount,
                    onSignOut: onSignOut,
                    onForget: onForget
                )
            } else {
                gamesPage
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task { viewModel.loadIfNeeded() }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            Text("PixelNOW")
                .font(.headline)

            Divider()
                .frame(height: 22)

            Button("Games") { viewModel.showGames() }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.selectedMainPage == .games ? .primary : .secondary)

            Button("Library") { viewModel.showCatalogDestination(.library) }
                .buttonStyle(.plain)
                .foregroundStyle(isLibrarySelected ? .primary : .secondary)

            Button("Favorites") { viewModel.showCatalogDestination(.favorites) }
                .buttonStyle(.plain)
                .foregroundStyle(isFavoritesSelected ? .primary : .secondary)

            Button("Recordings") { viewModel.showRecordings() }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.selectedMainPage == .recordings ? .primary : .secondary)

            Button("Settings") { viewModel.showSettings() }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.selectedMainPage == .settings ? .primary : .secondary)

            Spacer()

            Button {
                viewModel.refresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isCatalogRefreshInProgress)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var gamesPage: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    TextField("Search games", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)

                    if !viewModel.searchQuery.isEmpty {
                        Button("Clear") { viewModel.clearSearchAndFilters() }
                    }
                }

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.isLoading && games.isEmpty {
                    ProgressView("Loading games…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if games.isEmpty {
                    ContentUnavailableView("No games", systemImage: "gamecontroller", description: Text("No games are available for this view."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                            ForEach(games, id: \.uuid) { game in
                                BasicGameCard(
                                    game: game,
                                    isSelected: viewModel.selectedGame?.id == game.id,
                                    isFavorite: viewModel.isFavorite(game),
                                    play: { performPrimaryAction(for: game) },
                                    select: { viewModel.selectGame(game) },
                                    toggleFavorite: {
                                        viewModel.selectGame(game)
                                        viewModel.toggleFavoriteSelectedGame()
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if viewModel.selectedGame != nil {
                Divider()
                BasicGameInspector(viewModel: viewModel, play: { performPrimaryAction(for: viewModel.selectedGame) })
                    .frame(width: 300)
            }
        }
    }

    private var isLibrarySelected: Bool {
        viewModel.selectedMainPage == .games && viewModel.selectedCatalogDestination == .library
    }

    private var isFavoritesSelected: Bool {
        viewModel.selectedMainPage == .games && viewModel.selectedCatalogDestination == .favorites
    }

    private func gameIdentity(_ game: CatalogGameObject) -> String {
        [game.id, game.uuid, game.title].joined(separator: "|")
    }

    private func performPrimaryAction(for game: CatalogGameObject?) {
        guard let game else { return }
        viewModel.selectGame(game)
        if game.isLaunchPatching {
            viewModel.queuePatchingLaunch(game: game)
        } else if game.cardPrimaryActionIsLaunchable {
            viewModel.launch(game: game)
        } else {
            viewModel.beginMarkSelectedVariantOwnedFlow()
        }
    }
}

private struct BasicGameCard: View {
    let game: CatalogGameObject
    let isSelected: Bool
    let isFavorite: Bool
    let play: () -> Void
    let select: () -> Void
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: select) {
                HStack(alignment: .top, spacing: 10) {
                    CatalogRemoteImage(url: URL(string: game.bestTileImageURL), contentMode: .fill)
                        .frame(width: 82, height: 82)
                        .clipped()

                    VStack(alignment: .leading, spacing: 5) {
                        Text(game.title.isEmpty ? "Untitled game" : game.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Text(game.genres.prefix(2).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button(action: play) {
                    Text(game.isLaunchPatching ? "Queue" : (game.cardPrimaryActionIsLaunchable ? "Play" : "Mark Owned"))
                }
                .buttonStyle(.borderedProminent)

                Button(action: toggleFavorite) {
                    Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: isFavorite ? "heart.fill" : "heart")
                }
                .buttonStyle(.bordered)
                .labelStyle(.iconOnly)
                .help(isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
        }
    }
}

private struct BasicGameInspector: View {
    @ObservedObject var viewModel: CatalogViewModel
    let play: () -> Void

    var body: some View {
        if let game = viewModel.selectedGame {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Details")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Button("Close") { viewModel.selectGame(nil) }
                    }

                    CatalogRemoteImage(url: URL(string: game.bestDetailImageURL), contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)

                    Text(game.title.isEmpty ? "Untitled game" : game.title)
                        .font(.title2.weight(.semibold))

                    if !game.developerName.isEmpty {
                        Text(game.developerName)
                            .foregroundStyle(.secondary)
                    }

                    Text(game.shortDescription.isEmpty ? game.longDescription : game.shortDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(game.cardPrimaryActionIsLaunchable ? "Play" : "Mark Owned", action: play)
                        .buttonStyle(.borderedProminent)
                }
                .padding(20)
            }
        }
    }
}
