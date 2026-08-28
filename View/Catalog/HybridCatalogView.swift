import CryptoKit
import SwiftData
import SwiftUI

struct HybridCatalogView: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    @State private var selectedIdentity = ""
    @State private var backgroundIndex = 0
    @FocusState private var catalogHasFocus: Bool

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

    private var selectedGame: CatalogGameObject? {
        games.first { gameIdentity($0) == selectedIdentity } ?? games.first
    }

    var body: some View {
        ZStack {
            DynamicGameBackground(game: selectedGame, imageIndex: backgroundIndex)

            VStack(spacing: 0) {
                TopNavigationGlassBar(
                    viewModel: viewModel,
                    accounts: accounts,
                    onSwitch: onSwitch,
                    onAddAccount: onAddAccount,
                    onSignOut: onSignOut,
                    onForget: onForget
                )

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
                    catalogContent
                }
            }

            AccountGlassControl(
                account: viewModel.account,
                accounts: accounts,
                onSwitch: onSwitch,
                onAddAccount: onAddAccount,
                onSignOut: onSignOut,
                onForget: onForget
            )
        }
        .task { viewModel.loadIfNeeded() }
        .task(id: gameIdentity(selectedGame)) {
            backgroundIndex = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(9))
                guard !Task.isCancelled else { return }
                backgroundIndex += 1
            }
        }
        .onAppear {
            if selectedIdentity.isEmpty, let firstGame = games.first {
                select(firstGame)
            }
            catalogHasFocus = true
        }
        .onChange(of: games.map(gameIdentity)) { _, _ in
            guard let selectedGame else { return }
            select(selectedGame)
        }
    }

    private var catalogContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            if let selectedGame {
                FloatingGameDetails(
                    viewModel: viewModel,
                    game: selectedGame,
                    play: { performPrimaryAction(for: selectedGame) },
                    toggleFavorite: {
                        viewModel.selectGame(selectedGame)
                        viewModel.toggleFavoriteSelectedGame()
                    }
                )
                .transition(.opacity)
            }

            CurvedPosterRail(
                games: games,
                selectedIdentity: selectedIdentity,
                select: select,
                launch: { performPrimaryAction(for: $0) }
            )
            .frame(height: 150)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 28)
        .focusable(true)
        .focusEffectDisabled()
        .focused($catalogHasFocus)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                moveSelection(by: -1)
            case .right:
                moveSelection(by: 1)
            default:
                break
            }
        }
        .animation(.interactiveSpring(response: 0.26, dampingFraction: 0.9), value: selectedIdentity)
    }

    private func gameIdentity(_ game: CatalogGameObject?) -> String {
        guard let game else { return "" }
        return gameIdentity(game)
    }

    private func gameIdentity(_ game: CatalogGameObject) -> String {
        [game.id, game.uuid, game.title].joined(separator: "|")
    }

    private func select(_ game: CatalogGameObject) {
        selectedIdentity = gameIdentity(game)
        viewModel.selectGame(game)
    }

    private func moveSelection(by offset: Int) {
        guard !games.isEmpty else { return }
        let currentIndex = games.firstIndex { gameIdentity($0) == selectedIdentity } ?? 0
        let nextIndex = (currentIndex + offset + games.count) % games.count
        select(games[nextIndex])
    }

    private func performPrimaryAction(for game: CatalogGameObject) {
        select(game)
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
    }
}

private struct CurvedPosterRail: View {
    let games: [CatalogGameObject]
    let selectedIdentity: String
    let select: (CatalogGameObject) -> Void
    let launch: (CatalogGameObject) -> Void

    @State private var scrolledDisplayIdentity: String?

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .bottom, spacing: 14) {
                        ForEach(0..<(games.count * 3), id: \.self) { displayIndex in
                            let logicalIndex = displayIndex % games.count
                            let cycle = displayIndex / games.count
                            let game = games[logicalIndex]
                            let distance = distanceFromCenter(for: logicalIndex)
                            PosterGameCard(
                                game: game,
                                isSelected: cycle == 1 && gameIdentity(game) == selectedIdentity,
                                verticalOffset: curveOffset(distance: distance),
                                scale: curveScale(distance: distance),
                                select: { select(game) },
                                launch: { launch(game) }
                            )
                            .id(displayIdentity(cycle: cycle, game: game))
                        }
                    }
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, max(0, geometry.size.width / 2 - 99))
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledDisplayIdentity)
                .onAppear {
                    if !selectedIdentity.isEmpty {
                        scrollProxy.scrollTo(centerDisplayIdentity(for: selectedIdentity), anchor: .center)
                    }
                }
                .onChange(of: selectedIdentity) { _, identity in
                    guard !identity.isEmpty else { return }
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.9)) {
                        scrollProxy.scrollTo(centerDisplayIdentity(for: identity), anchor: .center)
                    }
                }
                .onChange(of: scrolledDisplayIdentity) { _, newId in
                    guard let newId = newId else { return }
                    let gameId = extractGameIdentity(from: newId)
                    if gameId != selectedIdentity, let game = games.first(where: { gameIdentity($0) == gameId }) {
                        select(game)
                    }
                }
            }
        }
    }

    private func gameIdentity(_ game: CatalogGameObject) -> String {
        [game.id, game.uuid, game.title].joined(separator: "|")
    }

    private func distanceFromCenter(for index: Int) -> CGFloat {
        let selectedIndex = games.firstIndex { gameIdentity($0) == selectedIdentity } ?? 0
        let directDistance = index - selectedIndex
        let wrappedDistance = directDistance > 0 ? directDistance - games.count : directDistance + games.count
        return CGFloat(abs(directDistance) <= abs(wrappedDistance) ? directDistance : wrappedDistance)
    }

    private func curveOffset(distance: CGFloat) -> CGFloat {
        0
    }

    private func curveScale(distance: CGFloat) -> CGFloat {
        1
    }

    private func displayIdentity(cycle: Int, game: CatalogGameObject) -> String {
        "\(cycle)-\(gameIdentity(game))"
    }

    private func centerDisplayIdentity(for identity: String) -> String {
        guard let game = games.first(where: { gameIdentity($0) == identity }) else { return identity }
        return displayIdentity(cycle: 1, game: game)
    }

    private func extractGameIdentity(from displayIdentity: String) -> String {
        let parts = displayIdentity.split(separator: "-", maxSplits: 1)
        return parts.count == 2 ? String(parts[1]) : displayIdentity
    }
}

private struct PosterGameCard: View {
    private static let cardWidth: CGFloat = 198
    private static let cardHeight: CGFloat = 118

    let game: CatalogGameObject
    let isSelected: Bool
    let verticalOffset: CGFloat
    let scale: CGFloat
    let select: () -> Void
    let launch: () -> Void

    @State private var isPulsing = false

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
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.18), lineWidth: isSelected ? (isPulsing ? 4 : 2) : 1)
                    .shadow(color: isSelected ? Color.accentColor.opacity(isPulsing ? 1.0 : 0.4) : .clear, radius: isSelected ? (isPulsing ? 20 : 8) : 0)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .scaleEffect(isSelected ? (isPulsing ? 1.05 : 1.0) : scale)
        .offset(y: verticalOffset)
        .onTapGesture(count: 2, perform: launch)
        .animation(.interactiveSpring(response: 0.24, dampingFraction: 0.86), value: isSelected)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isPulsing)
        .accessibilityLabel(game.title.isEmpty ? "Untitled game" : game.title)
        .accessibilityHint("Click to select. Double-click to launch.")
        .onAppear {
            if isSelected {
                isPulsing = true
            }
        }
        .onChange(of: isSelected) { _, selected in
            isPulsing = selected
        }
    }
}

private struct FloatingGameDetails: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject
    let play: () -> Void
    let toggleFavorite: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(game.title.isEmpty ? "Untitled game" : game.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !game.developerName.isEmpty {
                Text(game.developerName)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Text(game.shortDescription.isEmpty ? game.longDescription : game.shortDescription)
                .font(.callout)
                .foregroundStyle(.white.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .frame(maxWidth: 620)

            HStack(spacing: 10) {
                Button(game.isLaunchPatching ? "Queue" : (game.cardPrimaryActionIsLaunchable ? "Play" : "Mark Owned"), action: play)
                    .buttonStyle(.borderedProminent)
                Button(action: toggleFavorite) {
                    Image(systemName: viewModel.isFavorite(game) ? "heart.fill" : "heart")
                }
                .buttonStyle(.bordered)
                .help(viewModel.isFavorite(game) ? "Remove from favorites" : "Add to favorites")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .modifier(LiquidGlassModifier(cornerRadius: 22))
        .frame(maxWidth: 700)
    }
}

private struct TopNavigationGlassBar: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    var body: some View {
        HStack(spacing: 18) {
            Button("Games") { viewModel.showGames() }
            Button("Library") { viewModel.showCatalogDestination(.library) }
            Button("Favorites") { viewModel.showCatalogDestination(.favorites) }
            Button("Recordings") { viewModel.showRecordings() }
            Button("Settings") { viewModel.showSettings() }
            Button { viewModel.refresh() } label: { Image(systemName: "arrow.clockwise") }
                .disabled(viewModel.isCatalogRefreshInProgress)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .modifier(LiquidGlassModifier(cornerRadius: 24))
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 14)
        .safeAreaPadding(.horizontal, 20)
    }
}

private struct AccountGlassControl: View {
    let account: LoginAccount
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    var body: some View {
        Menu {
            ForEach(accounts, id: \.persistentModelID) { candidate in
                Button("Switch to \(candidate.displayName)") { onSwitch(candidate) }
            }
            Divider()
            Button("Add Account", action: onAddAccount)
            Button("Forget Account", role: .destructive) { onForget(account) }
            Button("Sign Out", role: .destructive, action: onSignOut)
        } label: {
            HStack(spacing: 10) {
                GravatarView(account: account, size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.displayName.isEmpty ? "Account" : account.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(account.membershipTier)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.68))
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .modifier(LiquidGlassModifier(cornerRadius: 18))
        .frame(maxWidth: 240, alignment: .leading)
        .safeAreaPadding(.trailing, 20)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

private struct GravatarView: View {
    let account: LoginAccount
    let size: CGFloat

    private var url: URL? {
        let email = account.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !email.isEmpty else { return nil }
        let hash = Insecure.MD5.hash(data: Data(email.utf8)).map { String(format: "%02x", $0) }.joined()
        return URL(string: "https://www.gravatar.com/avatar/\(hash)?s=\(Int(size * 3))&d=404")
    }

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.18))
            if let url {
                CatalogRemoteImage(url: url, contentMode: .fill)
                    .clipShape(Circle())
            } else {
                Text(String(account.displayName.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

private struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        } else {
            content.background(.regularMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
