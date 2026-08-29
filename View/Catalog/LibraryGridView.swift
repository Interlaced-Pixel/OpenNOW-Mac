import SwiftUI

enum LibrarySortOption: String, CaseIterable, Identifiable {
    case usageLatest = "Usage / Latest Release"
    case nameAsc = "Name (A-Z)"
    case nameDesc = "Name (Z-A)"
    case recent = "Recently Released"
    case oldest = "Oldest First"
    var id: String { rawValue }
}

struct LibraryGridView: View {
    @ObservedObject var viewModel: CatalogViewModel
    @ObservedObject var store: CatalogSelectionStore
    let play: (CatalogGameObject) -> Void

    let columns = [GridItem(.adaptive(minimum: 200), spacing: 24)]
    
    @State private var searchQuery = ""
    @State private var sortOption = LibrarySortOption.usageLatest

    var filteredAndSortedGames: [CatalogGameObject] {
        var result = store.games
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(trimmedQuery) }
        }

        switch sortOption {
        case .usageLatest:
            result.sort {
                if $0.isInLibrary != $1.isInLibrary {
                    return $0.isInLibrary && !$1.isInLibrary
                }
                let d0 = $0.releaseDate.isEmpty ? "0000" : $0.releaseDate
                let d1 = $1.releaseDate.isEmpty ? "0000" : $1.releaseDate
                if d0 != d1 {
                    return d0 > d1
                }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .nameAsc:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nameDesc:
            result.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .recent:
            result.sort {
                let d0 = $0.releaseDate.isEmpty ? "0000" : $0.releaseDate
                let d1 = $1.releaseDate.isEmpty ? "0000" : $1.releaseDate
                if d0 != d1 { return d0 > d1 }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        case .oldest:
            result.sort {
                let d0 = $0.releaseDate.isEmpty ? "9999" : $0.releaseDate
                let d1 = $1.releaseDate.isEmpty ? "9999" : $1.releaseDate
                if d0 != d1 { return d0 < d1 }
                return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        }

        return result
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search library...", text: $searchQuery)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .frame(maxWidth: 300)
                    
                    Spacer()
                    
                    Picker("Sort By", selection: $sortOption) {
                        ForEach(LibrarySortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
                .padding(.horizontal, 40)
                .padding(.top, 90)
                .padding(.bottom, 20)

                if store.games.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView().controlSize(.large)
                        Text("Loading catalog...").font(.headline).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredAndSortedGames.isEmpty {
                    VStack {
                        Spacer()
                        Text("No Games Found").font(.title2).foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(filteredAndSortedGames, id: \.id) { game in
                                    let identity = CatalogSelectionStore.gameIdentity(game)
                                    let isSelected = store.selectedGame.map(CatalogSelectionStore.gameIdentity) == identity
                                    GameCardView(
                                        game: game,
                                        isSelected: isSelected,
                                        select: { store.selectGame(withId: identity) },
                                        launch: { play(game) }
                                    )
                                    .id(identity)
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 60)
                        }
                        .onChange(of: store.selectedIndex) { _, newIndex in
                            guard store.games.indices.contains(newIndex) else { return }
                            let identity = CatalogSelectionStore.gameIdentity(store.games[newIndex])
                            withAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(identity, anchor: .center)
                            }
                        }
                    }
                }
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
    }
}

private struct LibrarySidePanel: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject?
    let play: () -> Void
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let game = game {
                Text(game.title.isEmpty ? "Untitled game" : game.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 12) {
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
                .lineLimit(2)

                let description = game.shortDescription.isEmpty ? game.longDescription : game.shortDescription
                Text(description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

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
