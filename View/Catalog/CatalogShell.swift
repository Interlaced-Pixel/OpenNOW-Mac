import SwiftUI

struct CatalogShell: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    @StateObject private var store = CatalogSelectionStore()
    @State private var backgroundIndex = 0
    @FocusState private var catalogHasFocus: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                DynamicGameBackground(game: store.selectedGame, imageIndex: backgroundIndex)
                    .frame(width: geometry.size.width, height: geometry.size.height)

                if viewModel.selectedMainPage == .recordings {
                    RecordingsView()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                } else if viewModel.selectedMainPage == .settings {
                    SettingsView(
                        viewModel: viewModel,
                        accounts: accounts,
                        onSwitch: onSwitch,
                        onAddAccount: onAddAccount,
                        onSignOut: onSignOut,
                        onForget: onForget
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else if viewModel.selectedCatalogDestination == .library {
                    LibraryGridView(
                        viewModel: viewModel,
                        store: store,
                        play: { game in performPrimaryAction(for: game) }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                } else {
                    VStack(spacing: 20) {
                        GameDetailOverlayPanel(
                            game: store.selectedGame,
                            isFavorite: {
                                if let g = store.selectedGame { return viewModel.isFavorite(g) }
                                return false
                            }(),
                            play: { if let g = store.selectedGame { performPrimaryAction(for: g) } },
                            toggleFavorite: {
                                if let g = store.selectedGame {
                                    viewModel.selectGame(g)
                                    viewModel.toggleFavoriteSelectedGame()
                                }
                            }
                        )

                        GameRailView(store: store) { game in
                            performPrimaryAction(for: game)
                        }
                    }
                    .frame(width: geometry.size.width, height: 390)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 30)
                }
            }
            .overlay(alignment: .top) {
                CatalogChrome(
                    viewModel: viewModel,
                    accounts: accounts,
                    onSwitch: onSwitch,
                    onAddAccount: onAddAccount,
                    onSignOut: onSignOut,
                    onForget: onForget
                )
            }
        }
        .focusable(true)
        .focusEffectDisabled()
        .focused($catalogHasFocus)
        .onMoveCommand { direction in
            if viewModel.selectedMainPage == .games {
                switch direction {
                case .left: store.selectPrevious()
                case .right: store.selectNext()
                default: break
                }
            }
        }
        .task { viewModel.loadIfNeeded() }
        .task(id: store.selectedGame?.id) {
            backgroundIndex = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(9))
                guard !Task.isCancelled else { return }
                backgroundIndex += 1
            }
        }
        .onAppear {
            if let selected = viewModel.selectedGame {
                store.setInitiallySelectedIdentity(CatalogSelectionStore.gameIdentity(selected))
            }
            if viewModel.selectedCatalogDestination != .library {
                store.load(from: viewModel.catalogSections)
            }
            catalogHasFocus = true
        }
        .onChange(of: viewModel.catalogSections) { _, newSections in
            if viewModel.selectedCatalogDestination != .library {
                store.load(from: newSections)
            }
        }
        .onChange(of: store.selectedIndex) { _, _ in
            if let game = store.selectedGame {
                viewModel.selectGame(game)
            }
        }
    }

    private func performPrimaryAction(for game: CatalogGameObject) {
        store.selectGame(withId: CatalogSelectionStore.gameIdentity(game))
        if game.isLaunchPatching {
            viewModel.queuePatchingLaunch(game: game)
        } else if game.cardPrimaryActionIsLaunchable {
            viewModel.launch(game: game)
        } else {
            viewModel.beginMarkSelectedVariantOwnedFlow()
        }
    }
}

private struct DynamicGameBackground: View {
    let game: CatalogGameObject?
    let imageIndex: Int

    private var imageURLs: [URL] {
        guard let game else { return [] }
        var values: [String] = []
        var seen = Set<String>()

        func append(_ value: String) {
            guard !value.isEmpty, seen.insert(value).inserted, let url = URL(string: value) else { return }
            values.append(url.absoluteString)
        }

        for key in ["HERO_IMAGE", "MARQUEE_HERO_IMAGE", "FEATURE_IMAGE", "KEY_ART", "TV_BANNER"] {
            for value in game.imageUrlsByType[key] ?? [] { append(value) }
            for value in game.imageUrlsByType[key.lowercased()] ?? [] { append(value) }
        }
        append(game.heroImageUrl)
        for value in game.screenshotUrls { append(value) }
        append(game.imageUrl)
        return values.compactMap(URL.init(string:))
    }

    var body: some View {
        ZStack {
            Color.black
            if let url = imageURLs.isEmpty ? nil : imageURLs[imageIndex % imageURLs.count] {
                CatalogRemoteImage(url: url, contentMode: .fill)
                    .id(url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 1.1), value: url)
                    .overlay(Color.black.opacity(0.38))
            }
            LinearGradient(
                colors: [.black.opacity(0.72), .black.opacity(0.10), .black.opacity(0.74)],
                startPoint: .top,
                endPoint: .bottom
            )
            LinearGradient(
                colors: [.black.opacity(0.58), .clear, .black.opacity(0.60)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea(.container, edges: [.horizontal, .bottom])
        .opacity(game == nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.3), value: game?.id)
    }
}
