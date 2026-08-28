import AppKit
import Combine
import SwiftData
import SwiftUI


// MARK: - Enums & Models

enum HybridFocusArea {
    case navigation
    case categories
    case content
}

enum HybridNavigationItem: CaseIterable, Equatable, Identifiable {
    case home
    case library
    case favorites
    case search
    case recordings
    case settings
    case actions

    var id: String { title }

    var title: String {
        switch self {
        case .home: return "Home"
        case .library: return "Library"
        case .favorites: return "Favorites"
        case .search: return "Search"
        case .recordings: return "Recordings"
        case .settings: return "Settings"
        case .actions: return "Actions"
        }
    }

    var icon: String {
        switch self {
        case .home: return "gamecontroller.fill"
        case .library: return "rectangle.stack.fill"
        case .favorites: return "heart.fill"
        case .search: return "magnifyingglass"
        case .recordings: return "play.rectangle.fill"
        case .settings: return "gearshape.fill"
        case .actions: return "ellipsis.circle.fill"
        }
    }
}

enum HybridDetailAction: Equatable {
    case primary
    case favorite
    case store
    case ownership
    case share
    case shortcut
    case visitStore
    case close

    @MainActor func title(game: CatalogGameObject, selectedVariant: CatalogGameVariantObject?, viewModel: CatalogViewModel) -> String {
        switch self {
        case .primary:
            if game.isLaunchPatching || selectedVariant?.isPatching == true { return viewModel.isQueuedForPatching(game) ? "Queued" : "Queue" }
            if viewModel.selectedPlatformHasAccess(in: game) { return "Play" }
            if selectedVariant != nil { return "Mark Owned" }
            return "Play"
        case .favorite: return viewModel.isFavorite(game) ? "Unfavorite" : "Favorite"
        case .store: return "Change Store"
        case .ownership:
            if selectedVariant.map({ CatalogViewModel.variantIsOwned($0, in: game) }) == true { return "Unmark Owned" }
            return "Mark Owned"
        case .share: return "Share"
        case .shortcut: return "Add Shortcut"
        case .visitStore: return "Visit Store"
        case .close: return "Close"
        }
    }

    var icon: String {
        switch self {
        case .primary: return "play.fill"
        case .favorite: return "heart.fill"
        case .store: return "bag.fill"
        case .ownership: return "checkmark.seal.fill"
        case .share: return "square.and.arrow.up"
        case .shortcut: return "plus.rectangle.on.rectangle"
        case .visitStore: return "safari.fill"
        case .close: return "xmark"
        }
    }
}

enum HybridActionMenuItem {
    case refresh
    case clearSearch
    case home
    case library
    case favorites
    case recordings
    case settings
    case switchAccount(LoginAccount)
    case addAccount
    case forgetAccount
    case signOut

    var title: String {
        switch self {
        case .refresh: return "Refresh Catalog"
        case .clearSearch: return "Clear Search and Filters"
        case .home: return "Go to Home"
        case .library: return "Go to Library"
        case .favorites: return "Go to Favorites"
        case .recordings: return "Open Recordings"
        case .settings: return "Open Settings"
        case .switchAccount(let account): return "Switch to \(account.displayName)"
        case .addAccount: return "Add Account"
        case .forgetAccount: return "Forget Current Account"
        case .signOut: return "Sign Out"
        }
    }

    var isRefresh: Bool {
        switch self {
        case .refresh: return true
        default: return false
        }
    }

    var icon: String {
        switch self {
        case .refresh: return "arrow.clockwise"
        case .clearSearch: return "line.3.horizontal.decrease.circle"
        case .home: return "gamecontroller.fill"
        case .library: return "rectangle.stack.fill"
        case .favorites: return "heart.fill"
        case .recordings: return "play.rectangle.fill"
        case .settings: return "gearshape.fill"
        case .switchAccount: return "person.crop.circle"
        case .addAccount: return "person.crop.circle.badge.plus"
        case .forgetAccount: return "person.crop.circle.badge.minus"
        case .signOut: return "rectangle.portrait.and.arrow.right"
        }
    }
}

// MARK: - HybridCatalogViewModel

@MainActor
final class HybridCatalogViewModel: ObservableObject {
    @Published var focusArea = HybridFocusArea.navigation
    @Published var selectedNavigationIndex = 0
    @Published var selectedCategoryIndex = 0
    @Published var selectedRailIndex = 0
    @Published var selectedGameIndices: [String: Int] = [:]
    @Published var isActionMenuVisible = false
    @Published var actionMenuIndex = 0
    @Published var isSearchVisible = false
    @Published var searchRowIndex = 0
    @Published var searchFilterOptionIndices: [String: Int] = [:]
    @Published var searchResultIndex = 0
    @Published var searchResultColumnCount = 4
    @Published var isDetailVisible = false
    @Published var detailActionIndex = 0
    @Published var showAllSection: CatalogSectionModel?
    @Published var showAllIndex = 0
    @Published var showAllColumnCount = 4

    let navigationItems = HybridNavigationItem.allCases

    var hasHybridOverlay: Bool {
        isActionMenuVisible || isSearchVisible || isDetailVisible || showAllSection != nil
    }

    func selectedGameIndex(for section: CatalogSectionModel, gameCount: Int) -> Int {
        guard gameCount > 0 else { return 0 }
        return min(max(selectedGameIndices[section.id] ?? 0, 0), gameCount - 1)
    }

    func setSelectedGameIndex(_ index: Int, for section: CatalogSectionModel, gameCount: Int) {
        guard gameCount > 0 else {
            selectedGameIndices[section.id] = 0
            return
        }
        selectedGameIndices[section.id] = min(max(index, 0), gameCount - 1)
    }

    func clampRailSelection(sectionCount: Int) {
        selectedRailIndex = min(max(selectedRailIndex, 0), max(sectionCount - 1, 0))
    }

    func clampCategorySelection(categoryCount: Int) {
        selectedCategoryIndex = min(max(selectedCategoryIndex, 0), max(categoryCount - 1, 0))
    }
}

// MARK: - Layout Metrics

struct HybridLayoutMetrics {
    let size: CGSize
    let safeAreaInsets: EdgeInsets

    var contentWidth: CGFloat {
        max(size.width - leadingInset - trailingInset, 1)
    }

    var leadingInset: CGFloat {
        safeAreaInsets.leading + baseInset
    }

    var trailingInset: CGFloat {
        safeAreaInsets.trailing + baseInset
    }

    var compactHeight: Bool { size.height < 760 }
    var heroHeight: CGFloat { compactHeight ? 230 : 280 }
    var railPreferredTileWidth: CGFloat { compactHeight ? 278 : 300 }

    private var baseInset: CGFloat {
        min(max(visibleWidth * 0.035, 56), 84)
    }

    private var visibleWidth: CGFloat {
        max(size.width - safeAreaInsets.leading - safeAreaInsets.trailing, 1)
    }
}

// MARK: - Main View

struct HybridCatalogView: View {
    @ObservedObject var viewModel: CatalogViewModel
    let accounts: [LoginAccount]
    let onSwitch: (LoginAccount) -> Void
    let onAddAccount: () -> Void
    let onSignOut: () -> Void
    let onForget: (LoginAccount) -> Void

    @StateObject private var inputRouter = ControllerInputRouter()
    @StateObject private var hybridViewModel = HybridCatalogViewModel()
    @State private var hoveredGameId: String?

    private var navigationItems: [HybridNavigationItem] { hybridViewModel.navigationItems }
    private var categories: [HybridCatalogCategory] {
        var values = [HybridCatalogCategory(id: "all", title: "All Games", icon: "square.grid.2x2.fill")]
        var seen = Set<String>()
        for genre in viewModel.catalogSections.flatMap({ $0.games.flatMap(\.genres) }) {
            let title = genre.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = title.lowercased()
            guard !title.isEmpty, !seen.contains(key), values.count < 8 else { continue }
            seen.insert(key)
            values.append(HybridCatalogCategory(id: title, title: CatalogGenreCopy.displayName(title), icon: CatalogGenreCopy.icon(title)))
        }
        return values
    }

    private var catalogSections: [CatalogSectionModel] {
        viewModel.catalogSections
    }

    var body: some View {
        GeometryReader { proxy in
            let layout = HybridLayoutMetrics(size: proxy.size, safeAreaInsets: proxy.safeAreaInsets)
            ZStack {
                HybridBackground(viewModel: viewModel, game: focusedHeroGame)

                VStack(spacing: 0) {
                    HybridHeader(viewModel: viewModel, glyphs: inputRouter.glyphs, layout: layout)
                    HybridNavigationBar(
                        items: navigationItems,
                        selectedIndex: hybridViewModel.selectedNavigationIndex,
                        isFocused: hybridViewModel.focusArea == .navigation && !hasModalOverlay,
                        activeItem: activeNavigationItem,
                        layout: layout,
                        select: selectNavigationItem
                    )
                    hybridPage(layout: layout)
                    HybridHintBar(hints: hints, glyphs: inputRouter.glyphs, layout: layout)
                }
                .frame(width: layout.contentWidth, height: proxy.size.height, alignment: .top)
                .padding(.leading, layout.leadingInset)
                .padding(.trailing, layout.trailingInset)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()

                if hybridViewModel.isSearchVisible {
                    HybridSearchOverlay(
                        viewModel: viewModel,
                        glyphs: inputRouter.glyphs,
                        rowIndex: hybridViewModel.searchRowIndex,
                        filterOptionIndices: hybridViewModel.searchFilterOptionIndices,
                        resultIndex: hybridViewModel.searchResultIndex,
                        resultColumnCount: $hybridViewModel.searchResultColumnCount,
                        layout: layout,
                        selectSort: { index in setSort(at: index) },
                        selectFilter: { group, index in setFilterOption(group: group, index: index) },
                        selectResult: { game in openDetails(game, sectionId: "catalog-results") },
                        close: { closeSearchOverlay() },
                        clear: { viewModel.clearSearchAndFilters() },
                        hoveredGameId: $hoveredGameId
                    )
                    .transition(.opacity)
                    .zIndex(30)
                }

                if hybridViewModel.isDetailVisible, let game = viewModel.selectedGame {
                    HybridDetailOverlay(
                        viewModel: viewModel,
                        game: game,
                        selectedActionIndex: hybridViewModel.detailActionIndex,
                        actions: detailActions(for: game),
                        glyphs: inputRouter.glyphs,
                        layout: layout,
                        perform: executeDetailAction,
                        close: closeDetails
                    )
                    .transition(.opacity)
                    .zIndex(28)
                }

                if let showAllSection = currentShowAllSection {
                    HybridShowAllOverlay(
                        viewModel: viewModel,
                        section: showAllSection,
                        selectedIndex: hybridViewModel.showAllIndex,
                        columnCount: $hybridViewModel.showAllColumnCount,
                        glyphs: inputRouter.glyphs,
                        layout: layout,
                        select: { game in openDetails(game, sectionId: showAllSection.id) },
                        close: closeShowAll,
                        hoveredGameId: $hoveredGameId
                    )
                    .transition(.opacity)
                    .zIndex(26)
                }

                if hybridViewModel.isActionMenuVisible {
                    HybridActionMenuOverlay(
                        items: actionMenuItems,
                        selectedIndex: hybridViewModel.actionMenuIndex,
                        glyphs: inputRouter.glyphs,
                        layout: layout,
                        isRefreshingCatalog: viewModel.isCatalogRefreshInProgress,
                        perform: executeActionMenuItem,
                        close: closeActionMenu
                    )
                    .transition(.opacity)
                    .zIndex(34)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .background(HybridKeyboardInputBridge { command in inputRouter.sendKeyboardCommand(command) })
        .onAppear {
            inputRouter.onCommand = handleInput
            synchronizeNavigationSelection()
        }
        .onDisappear { inputRouter.onCommand = nil }
        .onChange(of: viewModel.selectedMainPage) { _, _ in synchronizeNavigationSelection() }
        .onChange(of: viewModel.selectedCatalogDestination) { _, _ in synchronizeNavigationSelection() }
        .onChange(of: catalogSections.map(\.id)) { _, _ in clampRailSelection() }
        .onChange(of: categories.map(\.id)) { _, _ in clampCategorySelection() }
        .onChange(of: viewModel.catalogGames.map(\.catalogIdentity)) { _, _ in
            hybridViewModel.searchResultIndex = min(hybridViewModel.searchResultIndex, max(viewModel.catalogGames.count - 1, 0))
        }
    }

    @ViewBuilder private func hybridPage(layout: HybridLayoutMetrics) -> some View {
        switch viewModel.selectedMainPage {
        case .games:
            HybridGamesPage(
                viewModel: viewModel,
                focusArea: hybridViewModel.focusArea,
                categories: categories,
                selectedCategoryIndex: hybridViewModel.selectedCategoryIndex,
                selectedRailIndex: hybridViewModel.selectedRailIndex,
                selectedGameIndices: $hybridViewModel.selectedGameIndices,
                layout: layout,
                openDetails: openDetails,
                showAll: openShowAll,
                selectCategory: selectCategory,
                hoveredGameId: $hoveredGameId
            )
        case .recordings:
            HybridEmbeddedPage(title: "Recordings", subtitle: "Saved gameplay videos", layout: layout) {
                RecordingsView()
            }
        case .settings:
            HybridEmbeddedPage(title: "Settings", subtitle: "Streaming, account, interface, and system options", layout: layout) {
                SettingsView(
                    viewModel: viewModel,
                    accounts: accounts,
                    onSwitch: onSwitch,
                    onAddAccount: onAddAccount,
                    onSignOut: onSignOut,
                    onForget: onForget
                )
            }
        }
    }

    private var hasModalOverlay: Bool {
        hybridViewModel.hasHybridOverlay || viewModel.isLaunchFlowVisible || viewModel.isStorePickerVisible
    }

    private var activeNavigationItem: HybridNavigationItem {
        if viewModel.selectedMainPage == .recordings { return .recordings }
        if viewModel.selectedMainPage == .settings { return .settings }
        switch viewModel.selectedCatalogDestination {
        case .home: return .home
        case .library: return .library
        case .favorites: return .favorites
        }
    }

    private var focusedHeroGame: CatalogGameObject? {
        if hybridViewModel.isDetailVisible, let selectedGame = viewModel.selectedGame { return selectedGame }
        let sections = catalogSections
        if sections.indices.contains(hybridViewModel.selectedRailIndex) {
            let section = sections[hybridViewModel.selectedRailIndex]
            let games = section.visibleGames(expanded: false).filter(viewModel.matchesSelectedGenre)
            if let firstGame = games.first { return firstGame }
        }
        return viewModel.heroRotationGames.first ?? sections.flatMap(\.games).first
    }

    private var hints: [HybridHint] {
        if hybridViewModel.isActionMenuVisible { return [.move, .select, .back] }
        if hybridViewModel.isSearchVisible { return [.move, .select, .back, .clear] }
        if hybridViewModel.isDetailVisible { return [.move, .select, .back, .search] }
        if hybridViewModel.showAllSection != nil { return [.move, .select, .back] }
        if hybridViewModel.focusArea == .categories { return [.move, .select, .back, .search, .menu] }
        if hybridViewModel.focusArea == .content { return [.move, .select, .back, .search, .showAll, .menu] }
        return [.move, .select, .back, .search, .menu]
    }

    private var actionMenuItems: [HybridActionMenuItem] {
        var items: [HybridActionMenuItem] = [.refresh]
        if viewModel.isBrowseMode { items.append(.clearSearch) }
        items.append(contentsOf: [.home, .library, .favorites, .recordings, .settings])
        for account in accounts {
            let isCurrent: Bool
            if let lhs = AccountStorageKeys.requireUserId(account.userId),
               let rhs = AccountStorageKeys.requireUserId(viewModel.account.userId) {
                isCurrent = lhs == rhs
            } else {
                isCurrent = account.persistentModelID == viewModel.account.persistentModelID
            }
            if !isCurrent {
                items.append(.switchAccount(account))
            }
        }
        items.append(contentsOf: [.addAccount, .forgetAccount, .signOut])
        return items
    }

    private func handleInput(_ command: ControllerInputCommand) {
        if handleSharedOverlayInput(command) { return }
        if hybridViewModel.isActionMenuVisible { handleActionMenuInput(command); return }
        if hybridViewModel.isSearchVisible { handleSearchInput(command); return }
        if hybridViewModel.showAllSection != nil { handleShowAllInput(command); return }
        if hybridViewModel.isDetailVisible { handleDetailInput(command); return }
        handlePageInput(command)
    }

    private func handleSharedOverlayInput(_ command: ControllerInputCommand) -> Bool {
        if viewModel.isLaunchFlowVisible {
            switch command {
            case .back:
                viewModel.cancelVendorLaunch()
                return true
            case .confirm:
                if viewModel.launchFlowState == .activeSessionPrompt {
                    if viewModel.canResumeActiveLaunchSession { viewModel.resumeActiveLaunchSession() }
                    else { viewModel.endActiveSessionAndLaunchSelectedGame() }
                    return true
                }
                return false
            default:
                return true
            }
        }

        if viewModel.isStorePickerVisible {
            switch command {
            case .back:
                viewModel.closeStorePicker()
            case .move(.up), .move(.left):
                moveSelectedStore(delta: -1)
            case .move(.down), .move(.right):
                moveSelectedStore(delta: 1)
            case .confirm:
                confirmStorePickerStage()
            default:
                break
            }
            return true
        }
        return false
    }

    private func handlePageInput(_ command: ControllerInputCommand) {
        switch command {
        case .move(let direction):
            moveFocus(direction)
        case .confirm:
            confirmFocusedItem()
        case .back:
            if hybridViewModel.focusArea == .categories {
                hybridViewModel.focusArea = .navigation
            } else if viewModel.selectedMainPage != .games || viewModel.selectedCatalogDestination != .home {
                viewModel.showCatalogDestination(.home)
                hybridViewModel.focusArea = .content
            }
        case .search:
            openSearchOverlay()
        case .actions:
            if hybridViewModel.focusArea == .content, let section = currentSection {
                openShowAll(section)
            } else {
                openActionMenu()
            }
        case .menu:
            openActionMenu()
        case .pageLeft:
            moveRail(delta: -1)
        case .pageRight:
            moveRail(delta: 1)
        }
    }

    private func handleActionMenuInput(_ command: ControllerInputCommand) {
        let items = actionMenuItems
        switch command {
        case .move(.up): hybridViewModel.actionMenuIndex = max(hybridViewModel.actionMenuIndex - 1, 0)
        case .move(.down): hybridViewModel.actionMenuIndex = min(hybridViewModel.actionMenuIndex + 1, max(items.count - 1, 0))
        case .confirm:
            guard items.indices.contains(hybridViewModel.actionMenuIndex) else { return }
            executeActionMenuItem(items[hybridViewModel.actionMenuIndex])
        case .back, .menu, .actions: closeActionMenu()
        default: break
        }
    }

    private func handleSearchInput(_ command: ControllerInputCommand) {
        switch command {
        case .move(.up): hybridViewModel.searchRowIndex = max(hybridViewModel.searchRowIndex - 1, 0)
        case .move(.down): hybridViewModel.searchRowIndex = min(hybridViewModel.searchRowIndex + 1, max(searchRowCount - 1, 0))
        case .move(.left): moveSearchSelection(delta: -1)
        case .move(.right): moveSearchSelection(delta: 1)
        case .confirm: confirmSearchSelection()
        case .actions: viewModel.clearSearchAndFilters()
        case .back, .search: closeSearchOverlay()
        default: break
        }
    }

    private func handleShowAllInput(_ command: ControllerInputCommand) {
        guard let section = currentShowAllSection else { return }
        switch command {
        case .move(.left): hybridViewModel.showAllIndex = max(hybridViewModel.showAllIndex - 1, 0)
        case .move(.right): hybridViewModel.showAllIndex = min(hybridViewModel.showAllIndex + 1, max(section.games.count - 1, 0))
        case .move(.up): hybridViewModel.showAllIndex = max(hybridViewModel.showAllIndex - hybridViewModel.showAllColumnCount, 0)
        case .move(.down): hybridViewModel.showAllIndex = min(hybridViewModel.showAllIndex + hybridViewModel.showAllColumnCount, max(section.games.count - 1, 0))
        case .confirm:
            guard section.games.indices.contains(hybridViewModel.showAllIndex) else { return }
            openDetails(section.games[hybridViewModel.showAllIndex], sectionId: section.id)
        case .back, .actions, .menu: closeShowAll()
        case .search: openSearchOverlay()
        default: break
        }
    }

    private func handleDetailInput(_ command: ControllerInputCommand) {
        guard let game = viewModel.selectedGame else { return }
        let actions = detailActions(for: game)
        switch command {
        case .move(.left), .move(.up): hybridViewModel.detailActionIndex = max(hybridViewModel.detailActionIndex - 1, 0)
        case .move(.right), .move(.down): hybridViewModel.detailActionIndex = min(hybridViewModel.detailActionIndex + 1, max(actions.count - 1, 0))
        case .confirm:
            guard actions.indices.contains(hybridViewModel.detailActionIndex) else { return }
            executeDetailAction(actions[hybridViewModel.detailActionIndex])
        case .back: closeDetails()
        case .search: openSearchOverlay()
        case .actions, .menu: openActionMenu()
        default: break
        }
    }

    private func moveFocus(_ direction: ControllerInputDirection) {
        switch hybridViewModel.focusArea {
        case .navigation:
            switch direction {
            case .left: hybridViewModel.selectedNavigationIndex = max(hybridViewModel.selectedNavigationIndex - 1, 0)
            case .right: hybridViewModel.selectedNavigationIndex = min(hybridViewModel.selectedNavigationIndex + 1, max(navigationItems.count - 1, 0))
            case .down: hybridViewModel.focusArea = .content
            case .up: break
            }
        case .content:
            switch direction {
            case .left: moveGame(delta: -1)
            case .right: moveGame(delta: 1)
            case .up:
                if hybridViewModel.selectedRailIndex == 0 { hybridViewModel.focusArea = .navigation } else { moveRail(delta: -1) }
            case .down: moveRail(delta: 1)
            }
        case .categories:
            switch direction {
            case .left: hybridViewModel.selectedCategoryIndex = max(hybridViewModel.selectedCategoryIndex - 1, 0)
            case .right: hybridViewModel.selectedCategoryIndex = min(hybridViewModel.selectedCategoryIndex + 1, max(categories.count - 1, 0))
            case .up: hybridViewModel.focusArea = .navigation
            case .down: hybridViewModel.focusArea = .content
            }
        }
    }

    private func confirmFocusedItem() {
        if hybridViewModel.focusArea == .navigation {
            guard navigationItems.indices.contains(hybridViewModel.selectedNavigationIndex) else { return }
            selectNavigationItem(navigationItems[hybridViewModel.selectedNavigationIndex])
            return
        }
        if hybridViewModel.focusArea == .categories {
            guard categories.indices.contains(hybridViewModel.selectedCategoryIndex) else { return }
            selectCategory(categories[hybridViewModel.selectedCategoryIndex])
            return
        }
        guard let section = currentSection else { return }
        let games = section.visibleGames(expanded: false).filter(viewModel.matchesSelectedGenre)
        let index = clampedSelectedGameIndex(for: section, gameCount: games.count)
        guard games.indices.contains(index) else { return }
        openDetails(games[index], sectionId: section.id)
    }

    private func selectNavigationItem(_ item: HybridNavigationItem) {
        hybridViewModel.selectedNavigationIndex = navigationItems.firstIndex(of: item) ?? hybridViewModel.selectedNavigationIndex
        switch item {
        case .home:
            viewModel.showCatalogDestination(.home)
            hybridViewModel.focusArea = .categories
        case .library:
            viewModel.showCatalogDestination(.library)
            hybridViewModel.focusArea = .categories
        case .favorites:
            viewModel.showCatalogDestination(.favorites)
            hybridViewModel.focusArea = .categories
        case .search:
            openSearchOverlay()
        case .recordings:
            viewModel.showRecordings()
            hybridViewModel.focusArea = .navigation
        case .settings:
            viewModel.showSettings(.interface)
            hybridViewModel.focusArea = .navigation
        case .actions:
            openActionMenu()
        }
    }

    private var currentSection: CatalogSectionModel? {
        let sections = catalogSections
        guard sections.indices.contains(hybridViewModel.selectedRailIndex) else { return nil }
        return sections[hybridViewModel.selectedRailIndex]
    }

    private var currentShowAllSection: CatalogSectionModel? {
        guard let section = hybridViewModel.showAllSection else { return nil }
        return catalogSections.first { $0.id == section.id } ?? section
    }

    private func moveRail(delta: Int) {
        let sections = catalogSections
        guard !sections.isEmpty else { return }
        hybridViewModel.selectedRailIndex = min(max(hybridViewModel.selectedRailIndex + delta, 0), sections.count - 1)
    }

    private func moveGame(delta: Int) {
        guard let section = currentSection else { return }
        let gameCount = section.visibleGames(expanded: false).filter(viewModel.matchesSelectedGenre).count
        guard gameCount > 0 else { return }
        let index = clampedSelectedGameIndex(for: section, gameCount: gameCount)
        hybridViewModel.setSelectedGameIndex(index + delta, for: section, gameCount: gameCount)
    }

    private func clampedSelectedGameIndex(for section: CatalogSectionModel, gameCount: Int) -> Int {
        hybridViewModel.selectedGameIndex(for: section, gameCount: gameCount)
    }

    private func openDetails(_ game: CatalogGameObject, sectionId: String) {
        viewModel.selectGame(game, inSection: sectionId)
        hybridViewModel.detailActionIndex = 0
        hybridViewModel.isDetailVisible = true
        hybridViewModel.isSearchVisible = false
        hybridViewModel.showAllSection = nil
    }

    private func closeDetails() {
        hybridViewModel.isDetailVisible = false
        viewModel.selectGame(nil)
    }

    private func openSearchOverlay() {
        hybridViewModel.isSearchVisible = true
        hybridViewModel.isActionMenuVisible = false
        hybridViewModel.searchRowIndex = min(hybridViewModel.searchRowIndex, max(searchRowCount - 1, 0))
    }

    private func closeSearchOverlay() {
        hybridViewModel.isSearchVisible = false
    }

    private func openActionMenu() {
        hybridViewModel.actionMenuIndex = min(hybridViewModel.actionMenuIndex, max(actionMenuItems.count - 1, 0))
        hybridViewModel.isActionMenuVisible = true
    }

    private func closeActionMenu() {
        hybridViewModel.isActionMenuVisible = false
    }

    private func openShowAll(_ section: CatalogSectionModel) {
        hybridViewModel.showAllSection = section
        hybridViewModel.showAllIndex = clampedSelectedGameIndex(for: section, gameCount: section.games.count)
        viewModel.loadFullSectionIfNeeded(section)
    }

    private func closeShowAll() {
        hybridViewModel.showAllSection = nil
        hybridViewModel.showAllIndex = 0
    }

    private func detailActions(for game: CatalogGameObject) -> [HybridDetailAction] {
        var actions: [HybridDetailAction] = [.primary, .favorite]
        if game.variants.count > 1 { actions.append(.store) }
        if viewModel.selectedVariant(in: game) != nil { actions.append(.ownership) }
        actions.append(contentsOf: [.share, .shortcut, .visitStore, .close])
        return actions
    }

    private func executeDetailAction(_ action: HybridDetailAction) {
        guard let game = viewModel.selectedGame else { return }
        let selectedVariant = viewModel.selectedVariant(in: game)
        switch action {
        case .primary:
            if game.isLaunchPatching || selectedVariant?.isPatching == true {
                viewModel.queuePatchingLaunch(game: game, variantIndex: viewModel.selectedVariantIndex)
            } else if viewModel.selectedPlatformHasAccess(in: game) || selectedVariant == nil {
                viewModel.launchSelectedGame()
            } else {
                viewModel.handleUnownedSelectedVariantPrimaryAction()
            }
        case .favorite:
            viewModel.toggleFavoriteSelectedGame()
        case .store:
            viewModel.changeSelectedGameStore()
        case .ownership:
            if selectedVariant.map({ CatalogViewModel.variantIsOwned($0, in: game) }) == true {
                viewModel.removeSelectedVariantOwned()
            } else {
                viewModel.markSelectedVariantOwned()
            }
        case .share:
            viewModel.shareSelectedGame()
        case .shortcut:
            viewModel.addShortcutForSelectedGame()
        case .visitStore:
            viewModel.openStoreForSelectedVariant()
        case .close:
            closeDetails()
        }
    }

    private var searchRowCount: Int {
        2 + viewModel.visibleFilterGroups.count + (viewModel.catalogGames.isEmpty ? 0 : 1)
    }

    private func moveSearchSelection(delta: Int) {
        if hybridViewModel.searchRowIndex == 1 {
            let count = viewModel.sortOptions.count
            guard count > 0 else { return }
            let index = selectedSortIndex()
            setSort(at: min(max(index + delta, 0), count - 1))
            return
        }
        let filterStart = 2
        let filterEnd = filterStart + viewModel.visibleFilterGroups.count
        if hybridViewModel.searchRowIndex >= filterStart, hybridViewModel.searchRowIndex < filterEnd {
            let group = viewModel.visibleFilterGroups[hybridViewModel.searchRowIndex - filterStart]
            guard !group.options.isEmpty else { return }
            let index = min(max((hybridViewModel.searchFilterOptionIndices[group.id] ?? 0) + delta, 0), group.options.count - 1)
            hybridViewModel.searchFilterOptionIndices[group.id] = index
            return
        }
        if hybridViewModel.searchRowIndex == filterEnd, !viewModel.catalogGames.isEmpty {
            hybridViewModel.searchResultIndex = min(max(hybridViewModel.searchResultIndex + delta, 0), viewModel.catalogGames.count - 1)
        }
    }

    private func confirmSearchSelection() {
        if hybridViewModel.searchRowIndex == 0 {
            viewModel.browseCatalog()
            return
        }
        if hybridViewModel.searchRowIndex == 1 {
            setSort(at: selectedSortIndex())
            return
        }
        let filterStart = 2
        let filterEnd = filterStart + viewModel.visibleFilterGroups.count
        if hybridViewModel.searchRowIndex >= filterStart, hybridViewModel.searchRowIndex < filterEnd {
            let group = viewModel.visibleFilterGroups[hybridViewModel.searchRowIndex - filterStart]
            let index = hybridViewModel.searchFilterOptionIndices[group.id] ?? 0
            guard group.options.indices.contains(index) else { return }
            viewModel.toggleFilter(group.options[index].id)
            return
        }
        if hybridViewModel.searchRowIndex == filterEnd, viewModel.catalogGames.indices.contains(hybridViewModel.searchResultIndex) {
            openDetails(viewModel.catalogGames[hybridViewModel.searchResultIndex], sectionId: "catalog-results")
        }
    }

    private func selectedSortIndex() -> Int {
        viewModel.sortOptions.firstIndex { $0.id == viewModel.selectedSortId } ?? 0
    }

    private func setSort(at index: Int) {
        guard viewModel.sortOptions.indices.contains(index) else { return }
        viewModel.setSort(viewModel.sortOptions[index].id)
    }

    private func setFilterOption(group: CatalogFilterGroupObject, index: Int) {
        guard group.options.indices.contains(index) else { return }
        hybridViewModel.searchFilterOptionIndices[group.id] = index
        viewModel.toggleFilter(group.options[index].id)
    }

    private func executeActionMenuItem(_ item: HybridActionMenuItem) {
        if !item.isRefresh { closeActionMenu() }
        switch item {
        case .refresh:
            guard !viewModel.isCatalogRefreshInProgress else { return }
            viewModel.refresh()
        case .clearSearch:
            viewModel.clearSearchAndFilters()
        case .home:
            viewModel.showCatalogDestination(.home)
        case .library:
            viewModel.showCatalogDestination(.library)
        case .favorites:
            viewModel.showCatalogDestination(.favorites)
        case .recordings:
            viewModel.showRecordings()
        case .settings:
            viewModel.showSettings(.interface)
        case .switchAccount(let account):
            onSwitch(account)
        case .addAccount:
            onAddAccount()
        case .forgetAccount:
            onForget(viewModel.account)
        case .signOut:
            onSignOut()
        }
    }

    private func moveSelectedStore(delta: Int) {
        guard let game = viewModel.selectedGame else { return }
        let options = viewModel.platformOptions(for: game)
        guard options.count > 1 else { return }
        let currentIndex = viewModel.selectedVariantIndex >= 0 ? viewModel.selectedVariantIndex : CatalogViewModel.preferredVariantIndex(for: game)
        let currentOptionIndex = options.firstIndex { $0.variantIndex == currentIndex } ?? 0
        let nextOptionIndex = min(max(currentOptionIndex + delta, 0), options.count - 1)
        viewModel.focusGameStoreVariant(at: options[nextOptionIndex].variantIndex)
    }

    private func confirmStorePickerStage() {
        switch viewModel.ownershipFlowStage {
        case .storeSelection, .hidden:
            guard let option = viewModel.selectedPlatformOption(in: viewModel.selectedGame) else { return }
            viewModel.selectGameStoreVariant(at: option.variantIndex)
        case .manualMark:
            viewModel.confirmSelectedVariantOwned()
        case .success:
            viewModel.finishOwnershipFlow()
        case .resyncing:
            break
        }
    }

    private func synchronizeNavigationSelection() {
        let item = activeNavigationItem
        hybridViewModel.selectedNavigationIndex = navigationItems.firstIndex(of: item) ?? 0
        clampRailSelection()
    }

    private func clampRailSelection() {
        hybridViewModel.clampRailSelection(sectionCount: catalogSections.count)
    }

    private func clampCategorySelection() {
        hybridViewModel.clampCategorySelection(categoryCount: categories.count)
    }

    private func selectCategory(_ category: HybridCatalogCategory) {
        hybridViewModel.selectedCategoryIndex = categories.firstIndex(of: category) ?? 0
        hybridViewModel.focusArea = .content
        hybridViewModel.selectedRailIndex = 0
        if category.id == "all" {
            viewModel.selectGenreFilter("")
            viewModel.clearSearchAndFilters()
        } else {
            viewModel.selectGenreFilter(category.id)
        }
    }
}

// MARK: - Sub-views

private struct HybridBackground: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject?

    var body: some View {
        ZStack {
            Design.Catalog.canvas.ignoresSafeArea()
            if let game {
                CatalogRemoteImage(url: viewModel.optimizedImageURL(game.bestDetailImageURL, width: 1280), contentMode: .fill)
                    .ignoresSafeArea()
                    .blur(radius: 44)
                    .opacity(0.26)
            }
            LinearGradient(colors: [.black.opacity(0.84), .black.opacity(0.38), .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}

private struct HybridHeader: View {
    @ObservedObject var viewModel: CatalogViewModel
    let glyphs: ControllerInputGlyphSet
    let layout: HybridLayoutMetrics
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("PIXELNOW")
                    .font(.nvidia(size: 12, weight: .bold))
                    .foregroundStyle(Design.Catalog.brand)
                    .tracking(1.8)
                Text(headerTitle)
                    .font(.nvidia(size: 22, weight: .bold))
                    .foregroundStyle(.white.opacity(0.96))
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                Circle()
                    .fill(syncIsActive ? Design.Catalog.warning : Design.Catalog.ready)
                    .frame(width: 7, height: 7)
                Text(syncLabel)
                    .font(.nvidia(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.62))
            }
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background((syncIsActive ? Design.Catalog.warning : Design.Catalog.ready).opacity(0.10))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke((syncIsActive ? Design.Catalog.warning : Design.Catalog.ready).opacity(0.28), lineWidth: 1)
            }
            HybridDeviceBadge(glyphs: glyphs)
            CatalogAccountAvatar(account: viewModel.account, size: 34)
                .onHover { hovering in isHovered = hovering }
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.2), value: isHovered)
        }
        .frame(width: layout.contentWidth)
        .frame(height: 72)
        .background {
            Color.clear
            WindowDragArea()
        }
    }

    private var headerTitle: String {
        switch viewModel.selectedMainPage {
        case .games: return viewModel.selectedCatalogDestination.title
        case .recordings: return "Recordings"
        case .settings: return viewModel.selectedSettingsPage.title
        }
    }

    private var syncIsActive: Bool {
        viewModel.isLoading || viewModel.isLoadingPanels
    }

    private var syncLabel: String {
        if syncIsActive { return "SYNCING LIBRARY" }
        if viewModel.libraryGames.isEmpty { return "LIBRARY NOT SYNCED" }
        return "CLOUD SYNCED"
    }
}

private struct HybridDeviceBadge: View {
    let glyphs: ControllerInputGlyphSet

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: glyphs.usesControllerGlyphs ? "gamecontroller.fill" : "keyboard")
                .font(.nvidia(size: 13, weight: .bold))
                .foregroundStyle(Design.Catalog.selection)
            Text(glyphs.deviceName)
                .font(.nvidia(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: 250, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .frame(maxWidth: 304)
        .background(Color.white.opacity(0.055))
        .overlay { Rectangle().stroke(Color.white.opacity(0.10), lineWidth: 1) }
    }
}

private struct HybridCatalogCategory: Identifiable, Equatable {
    let id: String
    let title: String
    let icon: String
}

private struct HybridNavigationBar: View {
    let items: [HybridNavigationItem]
    let selectedIndex: Int
    let isFocused: Bool
    let activeItem: HybridNavigationItem
    let layout: HybridLayoutMetrics
    let select: (HybridNavigationItem) -> Void
    @State private var hoveredItemId: String?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    let selected = index == selectedIndex && isFocused
                    let active = activeItem == item
                    let isHovered = hoveredItemId == item.id
                    Button { select(item) } label: {
                        HStack(spacing: 9) {
                            Image(systemName: item.icon)
                                .font(.nvidia(size: 14, weight: .bold))
                            Text(item.title.uppercased())
                                .font(.nvidia(size: 12, weight: .bold))
                                .tracking(0.8)
                        }
                        .foregroundStyle(selected || active || isHovered ? .white : .white.opacity(0.78))
                        .padding(.horizontal, 14)
                        .frame(height: 40)
                        .background(selected ? Design.Catalog.selectionFill : (active ? Design.Catalog.selectionFill.opacity(0.75) : Color.white.opacity(isHovered ? 0.1 : 0.065)))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(selected ? Design.Catalog.selectionStroke : (active ? Design.Catalog.selectionStroke.opacity(0.55) : Color.white.opacity(isHovered ? 0.2 : 0.10)), lineWidth: selected ? 2 : 1)
                        }
                        .onHover { hovering in
                            hoveredItemId = hovering ? item.id : nil
                        }
                        .onTapGesture { select(item) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: layout.contentWidth, alignment: .leading)
            .padding(.vertical, 10)
        }
        .frame(width: layout.contentWidth)
        .glassmorphismPanel()
    }
}

private struct HybridGamesPage: View {
    @ObservedObject var viewModel: CatalogViewModel
    let focusArea: HybridFocusArea
    let categories: [HybridCatalogCategory]
    let selectedCategoryIndex: Int
    let selectedRailIndex: Int
    @Binding var selectedGameIndices: [String: Int]
    let layout: HybridLayoutMetrics
    let openDetails: (CatalogGameObject, String) -> Void
    let showAll: (CatalogSectionModel) -> Void
    let selectCategory: (HybridCatalogCategory) -> Void
    @Binding var hoveredGameId: String?

    var body: some View {
        let sections = viewModel.catalogSections
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: layout.compactHeight ? 20 : 24) {
                        HybridHeroBillboard(viewModel: viewModel, game: heroGame(sections: sections), height: layout.heroHeight)
                            .frame(width: layout.contentWidth)
                            .padding(.top, layout.compactHeight ? 10 : 14)

                        HybridCategoryRail(
                            categories: categories,
                            selectedIndex: selectedCategoryIndex,
                            isFocused: focusArea == .categories,
                            select: selectCategory
                        )
                        .frame(width: layout.contentWidth)

                        if !viewModel.errorMessage.isEmpty {
                            CatalogMessageView(message: viewModel.errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .frame(width: layout.contentWidth)
                        }

                        if viewModel.isBrowseMode {
                            HybridBrowseSummary(viewModel: viewModel)
                                .frame(width: layout.contentWidth)
                        }

                        ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                            HybridGameRail(
                                viewModel: viewModel,
                                section: section,
                                selectedIndex: binding(for: section),
                                isFocused: focusArea == .content && selectedRailIndex == index,
                                layout: layout,
                                hoveredGameId: $hoveredGameId,
                                openDetails: { game in openDetails(game, section.id) },
                                showAll: { showAll(section) }
                            )
                            .id(section.id)
                        }

                        if sections.isEmpty && !viewModel.isLoading && !viewModel.isLoadingPanels {
                            CatalogEmptyDestinationView(viewModel: viewModel, destination: viewModel.selectedCatalogDestination)
                                .frame(width: layout.contentWidth)
                                .padding(.top, 44)
                        }
                    }
                    .padding(.bottom, 46)
                }
                .onChange(of: selectedRailIndex) { _, index in
                    guard sections.indices.contains(index) else { return }
                    withAnimation(.easeOut(duration: 0.18)) {
                        proxy.scrollTo(sections[index].id, anchor: .center)
                    }
                }
            }
        }
        .overlay {
            if (viewModel.isLoading || viewModel.isLoadingPanels) && sections.isEmpty {
                VendorSplashLoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func binding(for section: CatalogSectionModel) -> Binding<Int> {
        Binding(
            get: { selectedGameIndices[section.id] ?? 0 },
            set: { selectedGameIndices[section.id] = $0 }
        )
    }

    private func heroGame(sections: [CatalogSectionModel]) -> CatalogGameObject? {
        if sections.indices.contains(selectedRailIndex) {
            let section = sections[selectedRailIndex]
            let games = section.visibleGames(expanded: false).filter(viewModel.matchesSelectedGenre)
            if let firstGame = games.first { return firstGame }
        }
        return viewModel.heroRotationGames.first ?? sections.flatMap(\.games).first
    }
}

private struct HybridCategoryRail: View {
    let categories: [HybridCatalogCategory]
    let selectedIndex: Int
    let isFocused: Bool
    let select: (HybridCatalogCategory) -> Void
    @State private var hoveredCategoryId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("EXPLORE BY GENRE")
                    .font(.nvidia(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Design.Catalog.selection.opacity(0.88))
                Spacer(minLength: 0)
                Text("D-PAD OR MOUSE TO MOVE")
                    .font(.nvidia(size: 10, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.38))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        let isSelected = index == selectedIndex
                        let isHovered = hoveredCategoryId == category.id
                        Button { select(category) } label: {
                            HStack(spacing: 8) {
                                Image(systemName: category.icon)
                                    .font(.nvidia(size: 12, weight: .bold))
                                Text(category.title)
                                    .font(.nvidia(size: 12, weight: .bold))
                            }
                            .foregroundStyle(isSelected || isHovered ? Design.Catalog.selection : .white.opacity(0.76))
                            .padding(.horizontal, 13)
                            .frame(height: 36)
                            .background(isSelected ? Design.Catalog.selectionFill : Color.white.opacity(isHovered ? 0.1 : 0.065))
                            .overlay {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(isFocused && isSelected ? Design.Catalog.selectionStroke : (isSelected ? Design.Catalog.selectionStroke : Color.white.opacity(isHovered ? 0.2 : 0.12)), lineWidth: isFocused && isSelected ? 2 : 1)
                            }
                            .onHover { hovering in hoveredCategoryId = hovering ? category.id : nil }
                            .onTapGesture { select(category) }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.20))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isFocused ? Design.Catalog.selectionStroke : Color.white.opacity(0.08), lineWidth: isFocused ? 2 : 1)
        }
    }
}

private struct HybridHeroBillboard: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject?
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let game {
                CatalogRemoteImage(url: viewModel.optimizedImageURL(game.bestMarqueeHeroImageURL, width: 1920), contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                LinearGradient(colors: [.black.opacity(0.94), .black.opacity(0.48), .black.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.clear, .black.opacity(0.76)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 9) {
                    Text("READY TO PLAY IN THE CLOUD")
                        .font(.nvidia(size: 11, weight: .bold))
                        .tracking(1.6)
                        .foregroundStyle(Design.Catalog.ready)
                    Text(game.title.isEmpty ? "GeForce NOW" : game.title)
                        .font(.nvidia(size: height < 260 ? 31 : 36, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    HStack(spacing: 10) {
                        if !game.ratingLabel.isEmpty { HybridMetadataPill(text: game.ratingLabel) }
                        if game.supportsGamepad { HybridMetadataPill(text: "Gamepad") }
                        if game.isInLibrary { HybridMetadataPill(text: "In Library", highlighted: true) }
                        if game.isFreeToPlay { HybridMetadataPill(text: "Free to Play") }
                        if let badge = game.cardBadgeLabel { HybridMetadataPill(text: badge) }
                    }
                    Text(heroDescription(game))
                        .font(.nvidia(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.74))
                        .lineLimit(height < 260 ? 1 : 2)
                        .frame(maxWidth: 650, alignment: .leading)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, height < 260 ? 20 : 24)
                .frame(maxWidth: 720, maxHeight: .infinity, alignment: .bottomLeading)
            } else {
                CatalogImageFallback()
            }
        }
        .frame(height: height)
        .background(Color.black.opacity(0.34))
        .overlay { Rectangle().stroke(Color.white.opacity(0.12), lineWidth: 1) }
        .shadow(color: .black.opacity(0.38), radius: 28, y: 18)
        .clipped()
    }

    private func heroDescription(_ game: CatalogGameObject) -> String {
        let description = game.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !description.isEmpty { return description }
        let genre = game.genres.prefix(2).joined(separator: ", ")
        return genre.isEmpty ? "Play instantly with GeForce NOW cloud streaming." : "\(genre) available on GeForce NOW."
    }
}

private struct HybridBrowseSummary: View {
    @ObservedObject var viewModel: CatalogViewModel

    var body: some View {
        HStack(spacing: 10) {
            Text(viewModel.resultSummary.uppercased())
                .font(.nvidia(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.66))
            Text("SORT: \(viewModel.selectedSortLabel.uppercased())")
                .font(.nvidia(size: 12, weight: .bold))
                .foregroundStyle(Design.Catalog.selection.opacity(0.90))
            if viewModel.selectedFilterCount > 0 {
                Text("\(viewModel.selectedFilterCount) FILTER\(viewModel.selectedFilterCount == 1 ? "" : "S")")
                    .font(.nvidia(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.66))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(Color.white.opacity(0.055))
        .overlay { Rectangle().stroke(Color.white.opacity(0.10), lineWidth: 1) }
    }
}

private struct HybridGameRail: View {
    @ObservedObject var viewModel: CatalogViewModel
    let section: CatalogSectionModel
    @Binding var selectedIndex: Int
    let isFocused: Bool
    let layout: HybridLayoutMetrics
    @Binding var hoveredGameId: String?
    let openDetails: (CatalogGameObject) -> Void
    let showAll: () -> Void

    private var games: [CatalogGameObject] {
        section.visibleGames(expanded: false).filter(viewModel.matchesSelectedGenre)
    }
    private var canShowAll: Bool { section.canLoadFullList || section.games.count > games.count }
    private var itemSpacing: CGFloat { 18 }

    var body: some View {
        VStack(alignment: .leading, spacing: layout.compactHeight ? 10 : 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(section.title)
                    .font(.nvidia(size: isFocused ? 24 : 21, weight: .bold))
                    .foregroundStyle(isFocused ? .white : .white.opacity(0.84))
                Text("\(section.games.count) GAMES")
                    .font(.nvidia(size: 11, weight: .bold))
                    .foregroundStyle(Design.Catalog.selection.opacity(0.82))
                Spacer(minLength: 0)
                if canShowAll {
                    Button("SHOW ALL", action: showAll)
                        .buttonStyle(.plain)
                        .font(.nvidia(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .frame(width: layout.contentWidth, alignment: .leading)

            GeometryReader { geometry in
                let metrics = layoutMetrics(width: geometry.size.width)
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: itemSpacing) {
                        ForEach(Array(games.enumerated()), id: \.element.catalogIdentity) { offset, game in
                            HybridGameTile(
                                game: game,
                                imageURL: viewModel.optimizedImageURL(game.bestWideImageURL, width: 720),
                                isFocused: isFocused && selectedIndex == offset,
                                isHovered: hoveredGameId == game.catalogIdentity,
                                isQueuedForPatching: viewModel.isQueuedForPatching(game),
                                showsFreeAccountAccessBadges: viewModel.isFreeTierAccount,
                                tileSize: metrics.tileSize,
                                onHover: { hovering in hoveredGameId = hovering ? game.catalogIdentity : nil },
                                action: { openDetails(game) }
                            )
                        }
                    }
                    .frame(height: metrics.rowHeight, alignment: .leading)
                    .padding(.bottom, 8)
                }
            }
            .frame(height: estimatedRailHeight)
        }
        .onChange(of: games.count) { _, count in
            selectedIndex = min(selectedIndex, max(count - 1, 0))
        }
    }

    private var estimatedRailHeight: CGFloat {
        layout.compactHeight ? 178 : 196
    }

    private func layoutMetrics(width: CGFloat) -> HybridRailLayoutMetrics {
        let contentWidth = max(width, 1)
        let count = min(max(1, Int((contentWidth + itemSpacing) / (layout.railPreferredTileWidth + itemSpacing))), max(games.count, 1))
        let totalSpacing = CGFloat(max(count - 1, 0)) * itemSpacing
        let tileWidth = floor(max((contentWidth - totalSpacing) / CGFloat(count), 1))
        let tileHeight = floor(tileWidth * 9 / 16)
        return HybridRailLayoutMetrics(visibleCount: count, tileSize: CGSize(width: tileWidth, height: tileHeight), rowHeight: tileHeight + 12)
    }
}

private struct HybridRailLayoutMetrics {
    let visibleCount: Int
    let tileSize: CGSize
    let rowHeight: CGFloat
}

private struct HybridGameTile: View {
    let game: CatalogGameObject
    let imageURL: URL?
    let isFocused: Bool
    let isHovered: Bool
    let isQueuedForPatching: Bool
    let showsFreeAccountAccessBadges: Bool
    let tileSize: CGSize
    let onHover: (Bool) -> Void
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                CatalogRemoteImage(url: imageURL, contentMode: .fill)
                    .frame(width: tileSize.width, height: tileSize.height)
                    .clipped()
                LinearGradient(colors: [.clear, .black.opacity(0.82)], startPoint: .top, endPoint: .bottom)
                if let badge = game.cardBadgeLabel {
                    CatalogGameCardBadge(label: badge)
                        .scaleEffect(0.92, anchor: .topLeading)
                }
                if let badge = game.freeAccountAccessBadgeLabel(isFreeTierAccount: showsFreeAccountAccessBadges) {
                    CatalogGameAccessBadge(label: badge)
                        .scaleEffect(0.92, anchor: .topTrailing)
                        .padding(9)
                        .frame(width: tileSize.width, height: tileSize.height, alignment: .topTrailing)
                }
                VStack(alignment: .leading, spacing: 7) {
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        if game.isLaunchPatching {
                            Image(systemName: isQueuedForPatching ? "clock.fill" : "wrench.and.screwdriver.fill")
                                .font(.nvidia(size: 12, weight: .bold))
                                .foregroundStyle(Design.Catalog.ready)
                        }
                        Text(game.title.isEmpty ? "GeForce NOW" : game.title)
                            .font(.nvidia(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Text(subtitle)
                        .font(.nvidia(size: 11, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
                .padding(15)
            }
            .frame(width: tileSize.width, height: tileSize.height)
            .glassmorphismPanel()
            .glassHoverEffect(isHovered: isHovered || isFocused)
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: Design.Glass.panelCornerRadius, style: .continuous)
                        .stroke(Design.Catalog.selectionStroke, lineWidth: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
        .onTapGesture(perform: action)
        .accessibilityLabel(game.title.isEmpty ? "Game" : game.title)
    }

    private var subtitle: String {
        if game.isLaunchPatching { return isQueuedForPatching ? "Queued for patch completion" : game.patchStatusPrimaryDisplayText }
        if game.isInLibrary || game.variants.contains(where: { $0.inLibrary || $0.librarySelected }) { return "Cloud ready • In Library" }
        if game.isFreeToPlay { return "Free to play • Add to library" }
        if !game.membershipTierLabel.isEmpty { return "\(game.membershipTierLabel) membership required" }
        if !game.primaryStoreLabel.isEmpty { return game.primaryStoreLabel }
        return game.supportsGamepad ? "Gamepad supported" : "Cloud ready"
    }
}

private struct HybridEmbeddedPage<Content: View>: View {
    let title: String
    let subtitle: String
    let layout: HybridLayoutMetrics
    private let content: Content

    init(title: String, subtitle: String, layout: HybridLayoutMetrics, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.layout = layout
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.nvidia(size: 11, weight: .bold))
                    .foregroundStyle(Design.Catalog.selection)
                    .tracking(1.4)
                Text(subtitle)
                    .font(.nvidia(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }
            .frame(width: layout.contentWidth, alignment: .leading)
            .padding(.top, 20)

            content
                .clipShape(Rectangle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct HybridSearchOverlay: View {
    @ObservedObject var viewModel: CatalogViewModel
    let glyphs: ControllerInputGlyphSet
    let rowIndex: Int
    let filterOptionIndices: [String: Int]
    let resultIndex: Int
    @Binding var resultColumnCount: Int
    let layout: HybridLayoutMetrics
    let selectSort: (Int) -> Void
    let selectFilter: (CatalogFilterGroupObject, Int) -> Void
    let selectResult: (CatalogGameObject) -> Void
    let close: () -> Void
    let clear: () -> Void
    @Binding var hoveredGameId: String?

    var body: some View {
        GeometryReader { proxy in
            let columns = overlayColumnCount(width: layout.contentWidth, minimumWidth: 250, spacing: 14)
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.90)
                VStack(alignment: .leading, spacing: 18) {
                    HybridOverlayHeader(title: "Search Catalog", subtitle: "Search, sort, filter, and launch from the full catalog.", glyphs: glyphs, close: close)
                    searchField
                    sortRow
                    filterRows
                    resultsGrid(columns: columns)
                }
                .glassmorphismPanel()
                .frame(width: layout.contentWidth, alignment: .leading)
                .padding(.leading, layout.leadingInset)
                .padding(.trailing, layout.trailingInset)
                .padding(.top, 38)
                .padding(.bottom, 32)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .onAppear { resultColumnCount = columns }
            .onChange(of: columns) { _, value in resultColumnCount = value }
        }
    }

    private var searchField: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.nvidia(size: 18, weight: .bold))
                .foregroundStyle(rowIndex == 0 ? Design.Catalog.selection : .white.opacity(0.62))
            TextField("Search games, stores, genres, publishers, controls, ratings, or tags", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.nvidia(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .onSubmit { viewModel.browseCatalog() }
            if !viewModel.searchQuery.isEmpty {
                Button("CLEAR", action: { viewModel.searchQuery = "" })
                    .buttonStyle(.plain)
                    .font(.nvidia(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(Color.white.opacity(rowIndex == 0 ? 0.12 : 0.075))
        .overlay { Rectangle().stroke(rowIndex == 0 ? Design.Catalog.selectionStroke : Color.white.opacity(0.13), lineWidth: rowIndex == 0 ? 2 : 1) }
    }

    private var sortRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HybridOverlaySectionTitle("Sort")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(viewModel.sortOptions.enumerated()), id: \.element.id) { index, option in
                        HybridOptionChip(
                            title: option.label.isEmpty ? option.id : option.label,
                            isSelected: option.id == viewModel.selectedSortId,
                            isFocused: rowIndex == 1 && selectedSortIndex == index,
                            action: { selectSort(index) }
                        )
                    }
                }
            }
        }
    }

    private var filterRows: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(viewModel.visibleFilterGroups.enumerated()), id: \.element.id) { groupIndex, group in
                VStack(alignment: .leading, spacing: 10) {
                    HybridOverlaySectionTitle(group.label.isEmpty ? group.id : group.label)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(group.options.enumerated()), id: \.element.id) { optionIndex, option in
                                HybridOptionChip(
                                    title: option.label.isEmpty ? option.id : option.label,
                                    isSelected: viewModel.selectedFilterIds.contains(option.id),
                                    isFocused: rowIndex == 2 + groupIndex && (filterOptionIndices[group.id] ?? 0) == optionIndex,
                                    action: { selectFilter(group, optionIndex) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func resultsGrid(columns: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HybridOverlaySectionTitle(viewModel.resultSummary.isEmpty ? "Results" : viewModel.resultSummary)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns), spacing: 14) {
                    ForEach(Array(viewModel.catalogGames.enumerated()), id: \.element.catalogIdentity) { index, game in
                        HybridCompactGameCard(
                            viewModel: viewModel,
                            game: game,
                            isFocused: rowIndex == 2 + viewModel.visibleFilterGroups.count && resultIndex == index,
                            isHovered: hoveredGameId == game.catalogIdentity,
                            onHover: { hovering in hoveredGameId = hovering ? game.catalogIdentity : nil },
                            action: { selectResult(game) }
                        )
                    }
                }
                .padding(.bottom, 12)
            }
        }
    }

    private var selectedSortIndex: Int {
        viewModel.sortOptions.firstIndex { $0.id == viewModel.selectedSortId } ?? 0
    }
}

private struct HybridDetailOverlay: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject
    let selectedActionIndex: Int
    let actions: [HybridDetailAction]
    let glyphs: ControllerInputGlyphSet
    let layout: HybridLayoutMetrics
    let perform: (HybridDetailAction) -> Void
    let close: () -> Void

    private var selectedVariant: CatalogGameVariantObject? { viewModel.selectedVariant(in: game) }
    private var selectedPlatformOption: CatalogPlatformOption? { viewModel.selectedPlatformOption(in: game) }

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = min(layout.contentWidth * 0.62, 900)
            ZStack(alignment: .leading) {
                CatalogRemoteImage(url: viewModel.optimizedImageURL(game.bestDetailImageURL, width: 1920), contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                Color.black.opacity(0.58)
                LinearGradient(colors: [.black.opacity(0.94), .black.opacity(0.64), .clear], startPoint: .leading, endPoint: .trailing)
                LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .top, endPoint: .bottom)

                VStack(alignment: .leading, spacing: 18) {
                    HybridOverlayHeader(title: game.title.isEmpty ? "Selected Game" : game.title, subtitle: detailSubtitle, glyphs: glyphs, close: close)
                    detailMetadata
                    HybridCloudStatusCard(
                        title: cloudStatusTitle,
                        message: cloudStatusMessage,
                        systemImage: cloudStatusIcon,
                        isReady: cloudStatusIsReady
                    )
                    Text(detailDescription)
                        .font(.nvidia(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineSpacing(4)
                        .lineLimit(5)
                        .frame(maxWidth: 720, alignment: .leading)
                    detailRows
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                                Button { perform(action) } label: {
                                    let isPrimary = action == .primary
                                    let isHighlighted = index == selectedActionIndex
                                    HStack(spacing: 9) {
                                        Image(systemName: action.icon)
                                            .font(.nvidia(size: 14, weight: .bold))
                                        Text(action.title(game: game, selectedVariant: selectedVariant, viewModel: viewModel).uppercased())
                                            .font(.nvidia(size: 12, weight: .bold))
                                            .tracking(0.8)
                                    }
                                    .foregroundStyle(isHighlighted ? (isPrimary ? .black.opacity(0.88) : .white) : .white.opacity(0.86))
                                    .padding(.horizontal, 15)
                                    .frame(height: 44)
                                    .background(isHighlighted ? (isPrimary ? Design.Catalog.action : Design.Catalog.selectionFill) : Color.white.opacity(0.09))
                                    .overlay {
                                        Rectangle().stroke(
                                            isHighlighted ? (isPrimary ? Design.Catalog.action : Design.Catalog.selectionStroke) : Color.white.opacity(0.14),
                                            lineWidth: isHighlighted ? 2 : 1
                                        )
                                    }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture { perform(action) }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .glassmorphismPanel()
                .frame(width: panelWidth, alignment: .leading)
                .padding(.leading, layout.leadingInset)
                .padding(.trailing, layout.trailingInset)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private var detailSubtitle: String {
        let store = selectedPlatformOption?.title ?? game.primaryStoreLabel
        let ownership = selectedPlatformOption?.hasAccess == true ? "Ready" : (selectedPlatformOption?.status.isEmpty == false ? selectedPlatformOption?.status ?? "Ownership required" : "Ownership required")
        return [store, ownership].filter { !$0.isEmpty }.joined(separator: " • ")
    }

    private var detailDescription: String {
        let short = game.shortDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !short.isEmpty { return short }
        let long = game.longDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !long.isEmpty { return long }
        return "Play instantly through GeForce NOW cloud streaming."
    }

    private var cloudStatusTitle: String {
        if game.isLaunchPatching || selectedVariant?.isPatching == true {
            return "Patching before cloud launch"
        }
        if selectedPlatformOption?.hasAccess == true || (selectedPlatformOption == nil && game.isInLibrary) {
            return "Ready to play in the cloud"
        }
        if viewModel.isFreeTierAccount, game.freeAccountAccessBadgeLabel(isFreeTierAccount: true) != nil {
            return "Membership required"
        }
        if game.isFreeToPlay {
            return "Free-to-play game"
        }
        return "Ownership required"
    }

    private var cloudStatusMessage: String {
        if game.isLaunchPatching || selectedVariant?.isPatching == true {
            return game.patchStatusSecondaryDisplayText.isEmpty ? "GeForce NOW is preparing this game." : game.patchStatusSecondaryDisplayText
        }
        if selectedPlatformOption?.hasAccess == true || (selectedPlatformOption == nil && game.isInLibrary) {
            return "Your selected store account can launch this game."
        }
        if game.isFreeToPlay {
            return "Add the game to your connected store account before launching."
        }
        return selectedPlatformOption?.status.isEmpty == false ? selectedPlatformOption?.status ?? "Select an owned store version to launch." : "Select an owned store version to launch."
    }

    private var cloudStatusIcon: String {
        if game.isLaunchPatching || selectedVariant?.isPatching == true { return "clock.arrow.circlepath" }
        if cloudStatusIsReady { return "checkmark.circle.fill" }
        if game.isFreeToPlay { return "gift.fill" }
        return "lock.fill"
    }

    private var cloudStatusIsReady: Bool {
        selectedPlatformOption?.hasAccess == true || (selectedPlatformOption == nil && game.isInLibrary)
    }

    private var detailMetadata: some View {
        HStack(spacing: 8) {
            if !game.ratingLabel.isEmpty { HybridMetadataPill(text: game.ratingLabel) }
            if game.supportsGamepad { HybridMetadataPill(text: "Gamepad") }
            if game.supportsKeyboard { HybridMetadataPill(text: "Keyboard") }
            ForEach(Array(game.genres.prefix(3)), id: \.self) { genre in
                HybridMetadataPill(text: genre)
            }
            if game.isLaunchPatching { HybridMetadataPill(text: "Patching", highlighted: true) }
        }
        .frame(maxWidth: 720, alignment: .leading)
    }

    private var detailRows: some View {
        VStack(alignment: .leading, spacing: 8) {
            HybridDetailRow(label: "Publisher", value: game.publisherName)
            HybridDetailRow(label: "Developer", value: game.developerName)
            HybridDetailRow(label: "Stores", value: game.storeLine)
            HybridDetailRow(label: "Players", value: playerLine)
        }
    }

    private var playerLine: String {
        if game.maxOnlinePlayers > 1, game.maxLocalPlayers > 1 { return "1-\(game.maxLocalPlayers) local, online multiplayer" }
        if game.maxOnlinePlayers > 1 { return "Online multiplayer" }
        if game.maxLocalPlayers > 1 { return "1-\(game.maxLocalPlayers) local players" }
        return "Single player"
    }
}

private struct HybridCloudStatusCard: View {
    let title: String
    let message: String
    let systemImage: String
    let isReady: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.nvidia(size: 17, weight: .bold))
                .foregroundStyle(isReady ? Design.Catalog.ready : .white.opacity(0.78))
                .frame(width: 28, height: 28)
                .background(isReady ? Design.Catalog.ready.opacity(0.14) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.nvidia(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                Text(message)
                    .font(.nvidia(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.065))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isReady ? Design.Catalog.ready.opacity(0.42) : Color.white.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct HybridShowAllOverlay: View {
    @ObservedObject var viewModel: CatalogViewModel
    let section: CatalogSectionModel
    let selectedIndex: Int
    @Binding var columnCount: Int
    let glyphs: ControllerInputGlyphSet
    let layout: HybridLayoutMetrics
    let select: (CatalogGameObject) -> Void
    let close: () -> Void
    @Binding var hoveredGameId: String?

    var body: some View {
        GeometryReader { proxy in
            let columns = overlayColumnCount(width: layout.contentWidth, minimumWidth: 290, spacing: 16)
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.90)
                VStack(alignment: .leading, spacing: 18) {
                    HybridOverlayHeader(title: section.title, subtitle: subtitle, glyphs: glyphs, close: close)
                    ScrollViewReader { scrollProxy in
                        ScrollView(.vertical, showsIndicators: true) {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns), spacing: 16) {
                                ForEach(Array(section.games.enumerated()), id: \.element.catalogIdentity) { index, game in
                                    HybridCompactGameCard(
                                        viewModel: viewModel,
                                        game: game,
                                        isFocused: selectedIndex == index,
                                        isHovered: hoveredGameId == game.catalogIdentity,
                                        onHover: { hovering in hoveredGameId = hovering ? game.catalogIdentity : nil },
                                        action: { select(game) }
                                    )
                                    .id(game.catalogIdentity)
                                }
                            }
                            .padding(.bottom, 18)
                        }
                        .onChange(of: selectedIndex) { _, index in
                            guard section.games.indices.contains(index) else { return }
                            withAnimation(.easeInOut(duration: 0.18)) {
                                scrollProxy.scrollTo(section.games[index].catalogIdentity, anchor: .center)
                            }
                        }
                    }
                }
                .glassmorphismPanel()
                .frame(width: layout.contentWidth, alignment: .leading)
                .padding(.leading, layout.leadingInset)
                .padding(.trailing, layout.trailingInset)
                .padding(.top, 38)
                .padding(.bottom, 32)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
            .onAppear { columnCount = columns }
            .onChange(of: columns) { _, value in columnCount = value }
        }
    }

    private var subtitle: String {
        section.isLoadingFullList ? "Loading full list... \(section.games.count) games loaded" : "\(section.games.count) games"
    }
}

private func overlayColumnCount(width: CGFloat, minimumWidth: CGFloat, spacing: CGFloat) -> Int {
    max(2, Int((width + spacing) / (minimumWidth + spacing)))
}

private struct HybridActionMenuOverlay: View {
    let items: [HybridActionMenuItem]
    let selectedIndex: Int
    let glyphs: ControllerInputGlyphSet
    let layout: HybridLayoutMetrics
    let isRefreshingCatalog: Bool
    let perform: (HybridActionMenuItem) -> Void
    let close: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .trailing) {
                Color.black.opacity(0.58).onTapGesture(perform: close)
                VStack(alignment: .leading, spacing: 0) {
                    HybridOverlayHeader(title: "Controller Actions", subtitle: "Catalog navigation and account actions", glyphs: glyphs, close: close)
                        .padding(.horizontal, 22)
                        .padding(.top, 22)
                        .padding(.bottom, 12)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                Button { perform(item) } label: {
                                    HStack(spacing: 13) {
                                        if item.isRefresh, isRefreshingCatalog {
                                            ProgressView()
                                                .controlSize(.small)
                                                .tint(index == selectedIndex ? Design.Catalog.selection : Design.Catalog.selection.opacity(0.72))
                                                .scaleEffect(0.82)
                                                .frame(width: 28)
                                        } else {
                                            Image(systemName: item.icon)
                                                .font(.nvidia(size: 15, weight: .bold))
                                                .foregroundStyle(index == selectedIndex ? Design.Catalog.selection : Design.Catalog.selection.opacity(0.72))
                                                .frame(width: 28)
                                        }
                                        Text(item.isRefresh && isRefreshingCatalog ? "Refreshing Catalog" : item.title)
                                            .font(.nvidia(size: 15, weight: .bold))
                                    .foregroundStyle(index == selectedIndex ? .white : .white.opacity(0.88))
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 48)
                            .background(index == selectedIndex ? Design.Catalog.selectionFill : Color.white.opacity(0.055))
                            .overlay { Rectangle().stroke(index == selectedIndex ? Design.Catalog.selectionStroke : Color.white.opacity(0.10), lineWidth: index == selectedIndex ? 2 : 1) }
                                }
                                .buttonStyle(.plain)
                                .onTapGesture { perform(item) }
                                .disabled(item.isRefresh && isRefreshingCatalog)
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 22)
                    }
                }
                .glassmorphismPanel()
                .frame(width: min(420, layout.contentWidth), alignment: .topLeading)
                .background(Color(red: 18 / 255, green: 18 / 255, blue: 18 / 255).opacity(0.98))
                .overlay(alignment: .leading) { Rectangle().fill(Design.Catalog.selection).frame(width: 3) }
                .shadow(color: .black.opacity(0.54), radius: 34, x: -14, y: 20)
                .padding(.trailing, layout.trailingInset)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }
}

private struct HybridOverlayHeader: View {
    let title: String
    let subtitle: String
    let glyphs: ControllerInputGlyphSet
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title.uppercased())
                    .font(.nvidia(size: 27, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.nvidia(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            HStack(spacing: 8) {
                HybridGlyphPill(glyph: glyphs.back)
                Text("BACK")
                    .font(.nvidia(size: 11, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
            }
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.nvidia(size: 16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.80))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.08))
                    .overlay { Rectangle().stroke(Color.white.opacity(0.14), lineWidth: 1) }
            }
            .buttonStyle(.plain)
        }
        .glassmorphismPanel()
    }
}

private struct HybridCompactGameCard: View {
    @ObservedObject var viewModel: CatalogViewModel
    let game: CatalogGameObject
    let isFocused: Bool
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                CatalogRemoteImage(url: viewModel.optimizedImageURL(game.bestWideImageURL, width: 520), contentMode: .fill)
                    .frame(height: 128)
                    .clipped()
                Text(game.title.isEmpty ? "GeForce NOW" : game.title)
                    .font(.nvidia(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.94))
                    .lineLimit(1)
                Text(game.primaryStoreLabel.isEmpty ? (game.isInLibrary ? "In Library" : "Cloud ready") : game.primaryStoreLabel)
                    .font(.nvidia(size: 11, weight: .bold))
                    .foregroundStyle(Design.Catalog.ready.opacity(0.84))
                    .lineLimit(1)
            }
            .padding(10)
            .background(Color.white.opacity(isFocused || isHovered ? 0.12 : 0.055))
            .overlay { Rectangle().stroke(isFocused ? Design.Catalog.selectionStroke : Color.white.opacity(isHovered ? 0.2 : 0.10), lineWidth: isFocused ? 3 : 1) }
        }
        .buttonStyle(.plain)
        .onHover(perform: onHover)
        .onTapGesture(perform: action)
    }
}

private struct HybridOptionChip: View {
    let title: String
    let isSelected: Bool
    let isFocused: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(.nvidia(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(isSelected || isFocused || isHovered ? .white.opacity(0.92) : .white.opacity(0.82))
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background(isSelected || isFocused ? Design.Catalog.selectionFill : Color.white.opacity(isHovered ? 0.12 : 0.075))
                .overlay { Rectangle().stroke(isFocused ? Design.Catalog.selectionStroke : (isSelected ? Design.Catalog.selectionStroke.opacity(0.55) : Color.white.opacity(isHovered ? 0.2 : 0.12)), lineWidth: isFocused ? 2 : 1) }
        }
        .buttonStyle(.plain)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture(perform: action)
    }
}

private struct HybridOverlaySectionTitle: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(.nvidia(size: 12, weight: .bold))
            .tracking(1.1)
            .foregroundStyle(Design.Catalog.selection.opacity(0.86))
    }
}

private struct HybridMetadataPill: View {
    let text: String
    var highlighted = false

    var body: some View {
        Text(text.uppercased())
            .font(.nvidia(size: 11, weight: .bold))
            .tracking(0.7)
            .foregroundStyle(highlighted ? .white.opacity(0.92) : .white.opacity(0.82))
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background(highlighted ? Design.Catalog.selection.opacity(0.72) : Color.white.opacity(0.10))
            .overlay { Rectangle().stroke(highlighted ? Design.Catalog.selectionStroke : Color.white.opacity(0.14), lineWidth: 1) }
    }
}

private struct HybridDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        if !value.isEmpty {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(label.uppercased())
                    .font(.nvidia(size: 10, weight: .bold))
                    .tracking(0.7)
                    .foregroundStyle(.white.opacity(0.42))
                    .frame(width: 96, alignment: .leading)
                Text(value)
                    .font(.nvidia(size: 13, weight: .bold))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Hint Bar & Glyphs

private enum HybridHint: Equatable {
    case move
    case select
    case back
    case search
    case showAll
    case menu
    case clear
}

private struct HybridHintBar: View {
    let hints: [HybridHint]
    let glyphs: ControllerInputGlyphSet
    let layout: HybridLayoutMetrics

    var body: some View {
        HStack(spacing: 14) {
            ForEach(hints, id: \.self) { hint in
                HybridHintItem(hint: hint, glyphs: glyphs)
            }
            Spacer(minLength: 0)
            Text("Hybrid Input Mode")
                .font(.nvidia(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.38))
                .tracking(0.8)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(width: layout.contentWidth, alignment: .leading)
        .frame(height: 46)
        .glassmorphismPanel()
        .overlay(alignment: .top) { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) }
    }
}

private struct HybridHintItem: View {
    let hint: HybridHint
    let glyphs: ControllerInputGlyphSet

    var body: some View {
        HStack(spacing: 6) {
            if hint == .move {
                HybridKeyboardMovePill(glyphs: ControllerInputGlyphSet.keyboard)
                Text("/")
                    .font(.nvidia(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                ForEach(Array(controllerGlyphSet.enumerated()), id: \.offset) { _, glyph in
                    HybridGlyphPill(glyph: glyph, compact: true)
                }
            } else {
                ForEach(Array(keyboardGlyphSet.enumerated()), id: \.offset) { _, glyph in
                    HybridGlyphPill(glyph: glyph, compact: false)
                }
                Text("/")
                    .font(.nvidia(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                ForEach(Array(controllerGlyphSet.enumerated()), id: \.offset) { _, glyph in
                    HybridGlyphPill(glyph: glyph, compact: false)
                }
            }
            Text(title)
                .font(.nvidia(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.64))
                .tracking(0.5)
        }
    }

    private var keyboardGlyphSet: [ControllerInputGlyph] {
        let kb = ControllerInputGlyphSet.keyboard
        switch hint {
        case .move: return [kb.left, kb.up, kb.down, kb.right]
        case .select: return [kb.confirm]
        case .back: return [kb.back]
        case .search: return [kb.search]
        case .showAll: return [kb.actions]
        case .menu: return [kb.menu]
        case .clear: return [kb.actions]
        }
    }

    private var controllerGlyphSet: [ControllerInputGlyph] {
        switch hint {
        case .move: return [glyphs.left, glyphs.up, glyphs.down, glyphs.right]
        case .select: return [glyphs.confirm]
        case .back: return [glyphs.back]
        case .search: return [glyphs.search]
        case .showAll: return [glyphs.actions]
        case .menu: return [glyphs.menu]
        case .clear: return [glyphs.actions]
        }
    }

    private var title: String {
        switch hint {
        case .move: return "MOVE"
        case .select: return "SELECT"
        case .back: return "BACK"
        case .search: return "SEARCH"
        case .showAll: return "SHOW ALL"
        case .menu: return "MENU"
        case .clear: return "CLEAR"
        }
    }
}

private struct HybridGlyphPill: View {
    let glyph: ControllerInputGlyph
    var compact = false

    var body: some View {
        HStack(spacing: compact ? 0 : 5) {
            if !glyph.symbolName.isEmpty {
                Image(systemName: glyph.symbolName)
                    .font(.nvidia(size: compact ? 11 : 12, weight: .bold))
            }
            if shouldShowText {
                Text(glyph.fallbackText)
                    .font(.nvidia(size: compact ? 0 : 9, weight: .bold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(Color.pixelNowGreen)
        .padding(.horizontal, compact ? 6 : 7)
        .frame(minWidth: compact ? 25 : 0)
        .frame(height: 22)
        .background(Color.pixelNowGreen.opacity(0.12))
        .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.pixelNowGreen.opacity(0.30), lineWidth: 1) }
        .accessibilityLabel(glyph.accessibilityLabel)
    }

    private var shouldShowText: Bool {
        guard !compact else { return false }
        guard !["↑", "↓", "←", "→"].contains(glyph.fallbackText) else { return false }
        return true
    }
}

private struct HybridKeyboardMovePill: View {
    let glyphs: ControllerInputGlyphSet

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: glyphs.left.symbolName)
            Image(systemName: glyphs.up.symbolName)
            Image(systemName: glyphs.down.symbolName)
            Image(systemName: glyphs.right.symbolName)
        }
        .font(.nvidia(size: 11, weight: .bold))
        .foregroundStyle(Color.pixelNowGreen)
        .padding(.horizontal, 8)
        .frame(height: 22)
        .background(Color.pixelNowGreen.opacity(0.12))
        .overlay { RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.pixelNowGreen.opacity(0.30), lineWidth: 1) }
        .accessibilityLabel("Arrow keys")
    }
}

// MARK: - Keyboard Input Bridge

private struct HybridKeyboardInputBridge: NSViewRepresentable {
    let onCommand: (ControllerInputCommand) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCommand: onCommand)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitor()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onCommand = onCommand
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        var onCommand: (ControllerInputCommand) -> Void
        private var monitor: Any?

        init(onCommand: @escaping (ControllerInputCommand) -> Void) {
            self.onCommand = onCommand
        }

        func installMonitor() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                guard !MainActor.assumeIsolated({ Self.isTextInputActive }) else { return event }
                guard let command = Self.command(for: event) else { return event }
                self.onCommand(command)
                return nil
            }
        }

        func removeMonitor() {
            guard let monitor else { return }
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        @MainActor private static var isTextInputActive: Bool {
            guard let responder = NSApp.keyWindow?.firstResponder else { return false }
            return responder is NSTextView || String(describing: type(of: responder)).localizedCaseInsensitiveContains("Text")
        }

        private static func command(for event: NSEvent) -> ControllerInputCommand? {
            guard event.modifierFlags.intersection(.deviceIndependentFlagsMask).isEmpty else { return nil }
            switch event.keyCode {
            case 126: return .move(.up)
            case 125: return .move(.down)
            case 123: return .move(.left)
            case 124: return .move(.right)
            case 36, 76: return .confirm
            case 53: return .back
            case 3: return .search
            case 46: return .actions
            case 48: return .menu
            case 33: return .pageLeft
            case 30: return .pageRight
            default: return nil
            }
        }
    }
}
