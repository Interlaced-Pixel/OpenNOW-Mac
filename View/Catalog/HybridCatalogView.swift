import AppKit
import SwiftUI

struct HybridCatalogView: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void
    @StateObject private var inputRouter = ControllerInputRouter()
    @State private var focusedGame: CatalogGameObject?
    @State private var isSearchPresented = false
    @State private var isDetailPresented = false
    @State private var hoveredIdentity = ""

    private var sections: [CatalogSectionModel] { viewModel.catalogSections }
    private var categories: [String] {
        let genres = sections.flatMap { $0.games.flatMap(\.genres) }
        return ["All Games"] + Array(Set(genres.filter { !$0.isEmpty })).sorted().prefix(7)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HybridBackground(game: focusedGame ?? viewModel.heroRotationGames.first)
                VStack(spacing: 0) {
                    HybridHeader(destination: viewModel.selectedCatalogDestination, page: viewModel.selectedMainPage, account: accounts.first, openSearch: { isSearchPresented = true }, selectDestination: selectDestination, selectPage: selectPage)
                    if viewModel.selectedMainPage == .games {
                        HybridGamesPage(sections: sections, categories: categories, selectedGenre: viewModel.selectedGenreFilter, hoveredIdentity: $hoveredIdentity, chooseGenre: chooseGenre, chooseGame: openDetails)
                    } else if viewModel.selectedMainPage == .settings {
                        HybridEmbeddedPage(title: "Settings", subtitle: "Tune your PixelNOW experience") { SettingsView(viewModel: viewModel, accounts: accounts, onSwitch: onSwitch, onAddAccount: onAddAccount, onSignOut: onSignOut, onForget: onForget) }
                    } else {
                        HybridEmbeddedPage(title: "Recordings", subtitle: "Your captured gameplay") { RecordingsView() }
                    }
                    HybridHintBar(glyphs: inputRouter.glyphs, isControllerConnected: inputRouter.isControllerConnected)
                }
                .padding(.top, 12)
                if isDetailPresented, let game = focusedGame { HybridDetailOverlay(game: game, viewModel: viewModel, close: closeDetails).transition(.opacity).zIndex(20) }
                if isSearchPresented { HybridSearchOverlay(viewModel: viewModel, close: { isSearchPresented = false }, choose: openDetails).transition(.opacity).zIndex(22) }
            }.frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(ControllerKeyboardInputBridge { handleInput($0) })
        .onAppear { inputRouter.onCommand = handleInput }
        .onDisappear { inputRouter.onCommand = nil }
        .onChange(of: viewModel.selectedGame) { _, game in if game == nil { isDetailPresented = false } }
    }

    private func selectDestination(_ destination: CatalogDestination) { viewModel.showCatalogDestination(destination); isDetailPresented = false }
    private func selectPage(_ page: CatalogMainPage) { switch page { case .games: viewModel.showGames(); case .recordings: viewModel.showRecordings(); case .settings: viewModel.showSettings() } }
    private func chooseGenre(_ genre: String) { viewModel.selectGenreFilter(genre == "All Games" ? "" : genre) }
    private func openDetails(_ game: CatalogGameObject) { focusedGame = game; viewModel.selectGame(game); isDetailPresented = true }
    private func closeDetails() { isDetailPresented = false; viewModel.closeGameDetailsFromBackground() }
    private func handleInput(_ command: ControllerInputCommand) {
        if isSearchPresented { if command == .back || command == .search { isSearchPresented = false }; return }
        if isDetailPresented { if command == .back { closeDetails() }; if command == .confirm { viewModel.launchSelectedGame() }; return }
        switch command { case .search: isSearchPresented = true; case .back: selectPage(.games); case .confirm: if let game = focusedGame { openDetails(game) }; case .move, .actions, .menu, .pageLeft, .pageRight: if let game = sections.first?.visibleGames(expanded: false).first { focusedGame = game } }
    }
}

private struct HybridBackground: View {
    let game: CatalogGameObject?
    var body: some View {
        ZStack {
            Design.Catalog.canvas
            if let url = game.flatMap({ URL(string: $0.bestDetailImageURL) }) { AsyncImage(url: url) { image in image.resizable().scaledToFill().blur(radius: 44) } placeholder: { Color.clear }.opacity(0.26).transition(.opacity) }
            LinearGradient(colors: [.black.opacity(0.48), .clear, .black.opacity(0.86)], startPoint: .top, endPoint: .bottom)
            LinearGradient(colors: [.black.opacity(0.62), .clear], startPoint: .leading, endPoint: .trailing)
        }.ignoresSafeArea().animation(.easeInOut(duration: 0.35), value: game?.catalogIdentity)
    }
}

private struct HybridHeader: View {
    let destination: CatalogDestination
    let page: CatalogMainPage
    let account: LoginAccount?
    let openSearch: () -> Void
    let selectDestination: (CatalogDestination) -> Void
    let selectPage: (CatalogMainPage) -> Void
    var body: some View {
        HStack(spacing: 18) {
            Text("PIXELNOW").font(.nvidia(size: 24, weight: .bold)).tracking(2.4).foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(CatalogDestination.allCases) { item in HybridNavPill(title: item.title, icon: item == .home ? "house.fill" : item == .library ? "rectangle.stack.fill" : "heart.fill", isSelected: page == .games && destination == item) { selectDestination(item) } }
                HybridNavPill(title: "Recordings", icon: "play.rectangle.fill", isSelected: page == .recordings) { selectPage(.recordings) }
                HybridNavPill(title: "Settings", icon: "gearshape.fill", isSelected: page == .settings) { selectPage(.settings) }
            }
            Spacer()
            Button(action: openSearch) { Image(systemName: "magnifyingglass").font(.system(size: 17, weight: .semibold)).frame(width: 42, height: 42) }.buttonStyle(.plain).glassmorphismPanel()
            if let account { Text(account.displayName).font(.nvidia(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.8)).lineLimit(1) }
        }.padding(.horizontal, 34).padding(.bottom, 18)
    }
}

private struct HybridNavPill: View {
    let title: String; let icon: String; let isSelected: Bool; let action: () -> Void
    var body: some View { Button(action: action) { Label(title, systemImage: icon).font(.nvidia(size: 12, weight: .bold)).foregroundStyle(isSelected ? Color.black : .white.opacity(0.75)).padding(.horizontal, 15).frame(height: 38) }.buttonStyle(.plain).background(isSelected ? Design.Glass.accentTint : Color.white.opacity(0.07)).clipShape(Capsule()) }
}

private struct HybridGamesPage: View {
    let sections: [CatalogSectionModel]; let categories: [String]; let selectedGenre: String
    @Binding var hoveredIdentity: String
    let chooseGenre: (String) -> Void; let chooseGame: (CatalogGameObject) -> Void
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 28) {
                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 10) { ForEach(categories, id: \.self) { category in Button(category == "All Games" ? category : CatalogGenreCopy.displayName(category)) { chooseGenre(category) }.buttonStyle(.plain).font(.nvidia(size: 12, weight: .bold)).foregroundStyle(selectedGenre == category || (category == "All Games" && selectedGenre.isEmpty) ? .black : .white.opacity(0.78)).padding(.horizontal, 16).frame(height: 34).background(selectedGenre == category || (category == "All Games" && selectedGenre.isEmpty) ? Design.Glass.accentTint : Color.white.opacity(0.08)).clipShape(Capsule()) } } }
                ForEach(sections) { section in HybridRail(section: section, hoveredIdentity: $hoveredIdentity, chooseGame: chooseGame) }
                if sections.isEmpty { ContentUnavailableView("No games yet", systemImage: "gamecontroller", description: Text("Your catalog will appear here when it finishes loading.")) }
            }.padding(.horizontal, 34).padding(.bottom, 28)
        }
    }
}

private struct HybridRail: View {
    let section: CatalogSectionModel; @Binding var hoveredIdentity: String; let chooseGame: (CatalogGameObject) -> Void
    var body: some View { VStack(alignment: .leading, spacing: 12) { HStack { Text(section.title).font(.nvidia(size: 18, weight: .bold)).foregroundStyle(.white); Spacer(); Text("\(section.games.count) GAMES").font(.nvidia(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.45)) }; ScrollView(.horizontal, showsIndicators: true) { HStack(spacing: 14) { ForEach(section.visibleGames(expanded: false), id: \.catalogIdentity) { game in HybridGameTile(game: game, isHovered: hoveredIdentity == game.catalogIdentity, hoverChanged: { hoveredIdentity = $0 ? game.catalogIdentity : "" }, action: { chooseGame(game) }) } }.padding(.vertical, 7) } } }
}

private struct HybridGameTile: View {
    let game: CatalogGameObject; let isHovered: Bool; let hoverChanged: (Bool) -> Void; let action: () -> Void
    var body: some View { Button(action: action) { VStack(alignment: .leading, spacing: 8) { ZStack(alignment: .bottomLeading) { AsyncImage(url: URL(string: game.bestTileImageURL)) { image in image.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.08) }; if let badge = game.cardBadgeLabel { Text(badge.uppercased()).font(.nvidia(size: 9, weight: .bold)).foregroundStyle(.black).padding(.horizontal, 7).frame(height: 20).background(Design.Glass.accentTint).clipShape(Capsule()).padding(9) } }.frame(width: 218, height: 123).clipped().clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)); Text(game.title).font(.nvidia(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.92)).lineLimit(1).frame(width: 218, alignment: .leading) }.padding(8).glassmorphismPanel().glassHoverEffect(isHovered: isHovered) }.buttonStyle(.plain).onHover(perform: hoverChanged) }
}

private struct HybridDetailOverlay: View {
    let game: CatalogGameObject; @ObservedObject var viewModel: CatalogViewModel; let close: () -> Void
    var body: some View { ZStack(alignment: .topTrailing) { Color.black.opacity(0.48).ignoresSafeArea(); VStack(alignment: .leading, spacing: 20) { AsyncImage(url: URL(string: game.bestDetailImageURL)) { image in image.resizable().scaledToFill() } placeholder: { Color.white.opacity(0.08) }.frame(maxWidth: .infinity).frame(height: 300).clipped().clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)); Text(game.title).font(.nvidia(size: 32, weight: .bold)).foregroundStyle(.white); HStack { ForEach(game.genres.prefix(3), id: \.self) { Text(CatalogGenreCopy.displayName($0)).font(.nvidia(size: 11, weight: .bold)).foregroundStyle(.white.opacity(0.8)).padding(.horizontal, 11).frame(height: 27).background(Color.white.opacity(0.1)).clipShape(Capsule()) } }; Text(game.longDescription.isEmpty ? game.gameDescription : game.longDescription).font(.nvidia(size: 14, weight: .medium)).foregroundStyle(.white.opacity(0.7)).lineLimit(5); HStack(spacing: 12) { Button("PLAY", systemImage: "play.fill") { viewModel.launchSelectedGame() }.buttonStyle(.borderedProminent).tint(Design.Glass.accentTint).foregroundStyle(.black); Button("FAVORITE", systemImage: game.isFavorited ? "heart.fill" : "heart") { viewModel.toggleFavoriteSelectedGame() }.buttonStyle(.bordered) }; Spacer() }.padding(24).frame(maxWidth: 760, maxHeight: 670).glassmorphismPanel(); Button(action: close) { Image(systemName: "xmark").font(.headline).frame(width: 38, height: 38) }.buttonStyle(.plain).glassmorphismPanel().padding(18) }.padding(38) }
}

private struct HybridSearchOverlay: View {
    @ObservedObject var viewModel: CatalogViewModel; let close: () -> Void; let choose: (CatalogGameObject) -> Void
    var body: some View { ZStack { Color.black.opacity(0.68).ignoresSafeArea(); VStack(alignment: .leading, spacing: 18) { HStack { Text("SEARCH LIBRARY").font(.nvidia(size: 22, weight: .bold)).foregroundStyle(.white); Spacer(); Button(action: close) { Image(systemName: "xmark") }.buttonStyle(.plain) }; TextField("Search games", text: $viewModel.searchQuery).textFieldStyle(.roundedBorder).font(.nvidia(size: 16, weight: .medium)); Text(viewModel.resultSummary.isEmpty ? "Start typing to browse the catalog." : viewModel.resultSummary).font(.nvidia(size: 12, weight: .bold)).foregroundStyle(.white.opacity(0.55)); ScrollView { LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 14)], spacing: 14) { ForEach(viewModel.catalogGames, id: \.catalogIdentity) { game in HybridGameTile(game: game, isHovered: false, hoverChanged: { _ in }, action: { choose(game); close() }) } } } }.padding(28).frame(width: 760, height: 620).glassmorphismPanel() }.padding(40) }
}

private struct HybridEmbeddedPage<Content: View>: View {
    let title: String; let subtitle: String; @ViewBuilder let content: () -> Content
    var body: some View { VStack(alignment: .leading, spacing: 18) { Text(title).font(.nvidia(size: 27, weight: .bold)).foregroundStyle(.white); Text(subtitle).font(.nvidia(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.58)); content().frame(maxWidth: .infinity, maxHeight: .infinity).glassmorphismPanel() }.padding(.horizontal, 34).padding(.bottom, 18) }
}

private struct HybridHintBar: View {
    let glyphs: ControllerInputGlyphSet; let isControllerConnected: Bool
    var body: some View { HStack(spacing: 18) { HybridHintItem(key: "↑↓←→", label: "MOVE"); HybridHintItem(key: glyphs.confirm.fallbackText, label: "SELECT"); HybridHintItem(key: glyphs.back.fallbackText, label: "BACK"); HybridHintItem(key: glyphs.search.fallbackText, label: "SEARCH"); Spacer(); Text(isControllerConnected ? glyphs.deviceName.uppercased() : "KEYBOARD READY").font(.nvidia(size: 10, weight: .bold)).tracking(1).foregroundStyle(.white.opacity(0.42)) }.padding(.horizontal, 38).frame(height: 46) }
}

private struct HybridHintItem: View {
    let key: String; let label: String
    var body: some View { HStack(spacing: 7) { Text(key).font(.nvidia(size: 10, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 7).frame(height: 22).background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 5)); Text(label).font(.nvidia(size: 10, weight: .bold)).tracking(0.8).foregroundStyle(.white.opacity(0.45)) } }
}

private struct ControllerKeyboardInputBridge: NSViewRepresentable {
    let onCommand: (ControllerInputCommand) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onCommand: onCommand) }
    func makeNSView(context: Context) -> NSView { context.coordinator.installMonitor(); return NSView(frame: .zero) }
    func updateNSView(_ nsView: NSView, context: Context) { context.coordinator.onCommand = onCommand }
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) { coordinator.removeMonitor() }
    final class Coordinator {
        var onCommand: (ControllerInputCommand) -> Void; private var monitor: Any?
        init(onCommand: @escaping (ControllerInputCommand) -> Void) { self.onCommand = onCommand }
        func installMonitor() { guard monitor == nil else { return }; monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in guard let self, event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty, let command = Self.command(for: event) else { return event }; self.onCommand(command); return nil } }
        func removeMonitor() { if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil } }
        private static func command(for event: NSEvent) -> ControllerInputCommand? { switch event.keyCode { case 126: .move(.up); case 125: .move(.down); case 123: .move(.left); case 124: .move(.right); case 36, 76: .confirm; case 53: .back; case 3: .search; case 46: .actions; case 48: .menu; case 33: .pageLeft; case 30: .pageRight; default: nil } }
    }
}
