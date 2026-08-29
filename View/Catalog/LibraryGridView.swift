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
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        var result: [CatalogGameObject]

        if trimmedQuery.isEmpty {
            let owned = viewModel.libraryGames.filter { $0.isInLibrary || CatalogViewModel.gameHasOwnedVariant($0) }
            result = owned.isEmpty && !viewModel.libraryGames.isEmpty ? viewModel.libraryGames : owned
        } else {
            var pool: [CatalogGameObject] = []
            var seen = Set<String>()
            for game in viewModel.catalogGames + viewModel.allKnownGames {
                let identity = CatalogSelectionStore.gameIdentity(game)
                guard !identity.isEmpty, seen.insert(identity).inserted else { continue }
                pool.append(game)
            }
            result = pool.filter { $0.title.localizedCaseInsensitiveContains(trimmedQuery) }
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
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search all games...", text: $searchQuery)
                            .textFieldStyle(.plain)
                            .onChange(of: searchQuery) { _, newQuery in
                                let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                                if viewModel.searchQuery != trimmed {
                                    viewModel.searchQuery = trimmed
                                }
                            }
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

                if trimmedQuery.isEmpty && viewModel.libraryGames.isEmpty {
                    if viewModel.isCatalogRefreshInProgress {
                        VStack(spacing: 16) {
                            Spacer()
                            ProgressView().controlSize(.large)
                            Text("Loading library...").font(.headline).foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Text("No Games in Library").font(.title2).foregroundStyle(.secondary)
                            Text("Games you own or sync will appear here.").font(.subheadline).foregroundStyle(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else if filteredAndSortedGames.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView().controlSize(.large)
                            Text("Searching catalog...").font(.headline).foregroundStyle(.secondary)
                        } else {
                            Text("No Games Found").font(.title2).foregroundStyle(.secondary)
                        }
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
            .onAppear {
                store.load(from: filteredAndSortedGames)
            }
            .onChange(of: filteredAndSortedGames.map(CatalogSelectionStore.gameIdentity)) { _, _ in
                store.load(from: filteredAndSortedGames)
            }

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
        if let game = game {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title & Studio Info
                        headerSection(game: game)

                        // Highlight Badges (In Library, Free to Play, Patching, Tier)
                        badgesRow(game: game)

                        // Specs & Features Grid (Controls, Players, Cloud Saves)
                        specsGrid(game: game)

                        // NVIDIA Graphics Technologies
                        if !nvidiaTechItems(for: game).isEmpty {
                            nvidiaTechSection(game: game)
                        }

                        // Available Stores / Platforms
                        let stores = storeItems(for: game)
                        if !stores.isEmpty {
                            storesSection(stores: stores)
                        }

                        // Genres & Categories
                        if !game.genres.isEmpty {
                            genresSection(game: game)
                        }

                        // Content & Age Ratings
                        if let rating = ratingDisplay(for: game) {
                            ratingSection(rating: rating)
                        }

                        // Supported Languages
                        let languages = supportedLanguages(for: game)
                        if !languages.isEmpty {
                            languagesSection(languages: languages)
                        }

                        // Game Description / About
                        descriptionSection(game: game)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 84)
                    .padding(.bottom, 24)
                }

                Divider()
                    .background(Color.white.opacity(0.12))

                // Bottom Pinned Actions
                VStack(spacing: 10) {
                    let actionText = game.isLaunchPatching ? "Queue"
                        : (game.cardPrimaryActionIsLaunchable ? "Play" : "Mark Owned")
                    let actionIcon = game.isLaunchPatching ? "wrench.and.screwdriver.fill" : "play.fill"

                    Button(action: play) {
                        HStack(spacing: 8) {
                            Image(systemName: actionIcon)
                            Text(actionText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button(action: toggleFavorite) {
                        Label(viewModel.isFavorite(game) ? "Remove Favorite" : "Add to Favorites",
                              systemImage: viewModel.isFavorite(game) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: game.id)
        } else {
            VStack {
                Spacer()
                Text("Select a game to view details")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Subsections

    private func headerSection(game: CatalogGameObject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.title.isEmpty ? "Untitled Game" : game.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 5) {
                if !game.developerName.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "hammer.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(game.developerName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                if !game.publisherName.isEmpty && game.publisherName != game.developerName {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(game.publisherName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                if !game.releaseDate.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(formattedReleaseDate(game.releaseDate))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func badgesRow(game: CatalogGameObject) -> some View {
        let hasInLibrary = game.isInLibrary || game.variants.contains { $0.inLibrary || $0.librarySelected }
        let hasFree = game.isFreeToPlay
        let hasPatching = game.isLaunchPatching
        let hasTier = !game.membershipTierLabel.isEmpty

        if hasInLibrary || hasFree || hasPatching || hasTier {
            FlowLayout(spacing: 8) {
                if hasInLibrary {
                    SidePanelChip(
                        icon: "checkmark.circle.fill",
                        text: "In Library",
                        tintColor: Color.green.opacity(0.2),
                        foregroundColor: .green
                    )
                }
                if hasFree {
                    SidePanelChip(
                        icon: "gift.fill",
                        text: "Free to Play",
                        tintColor: Color.purple.opacity(0.2),
                        foregroundColor: Color(red: 0.8, green: 0.6, blue: 1.0)
                    )
                }
                if hasPatching {
                    SidePanelChip(
                        icon: "wrench.and.screwdriver.fill",
                        text: game.patchStatusPrimaryDisplayText,
                        tintColor: Color.orange.opacity(0.2),
                        foregroundColor: .orange
                    )
                }
                if hasTier {
                    SidePanelChip(
                        icon: "crown.fill",
                        text: game.membershipTierLabel,
                        tintColor: Color.yellow.opacity(0.2),
                        foregroundColor: .yellow
                    )
                }
            }
        }
    }

    private func specsGrid(game: CatalogGameObject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SidePanelSectionHeader(icon: "slider.horizontal.3", title: "Game Specs")

            FlowLayout(spacing: 8) {
                // Controls
                if game.supportsGamepad {
                    SidePanelChip(icon: "gamecontroller.fill", text: "Controller")
                }
                if game.supportsKeyboard {
                    SidePanelChip(icon: "keyboard.fill", text: "Keyboard & Mouse")
                }

                // Players
                ForEach(playerModeBadges(for: game), id: \.title) { mode in
                    SidePanelChip(icon: mode.icon, text: mode.title)
                }

                // Cloud Saves
                if hasCloudSaves(for: game) {
                    SidePanelChip(icon: "icloud.fill", text: "Cloud Saves")
                }
            }
        }
    }

    private func nvidiaTechSection(game: CatalogGameObject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SidePanelSectionHeader(icon: "sparkles", title: "NVIDIA RTX & Graphics")

            FlowLayout(spacing: 8) {
                ForEach(nvidiaTechItems(for: game), id: \.title) { tech in
                    SidePanelChip(
                        icon: tech.icon,
                        text: tech.title,
                        tintColor: Color(red: 0.46, green: 0.72, blue: 0.0).opacity(0.18),
                        foregroundColor: Color(red: 0.55, green: 0.85, blue: 0.0)
                    )
                }
            }
        }
    }

    private func storesSection(stores: [(title: String, isOwned: Bool, icon: String)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SidePanelSectionHeader(icon: "cart.fill", title: "Available Platforms")

            FlowLayout(spacing: 8) {
                ForEach(stores, id: \.title) { store in
                    SidePanelChip(
                        icon: store.icon,
                        text: store.isOwned ? "\(store.title) (Owned)" : store.title,
                        tintColor: store.isOwned ? Color.blue.opacity(0.2) : Color.white.opacity(0.08),
                        foregroundColor: store.isOwned ? Color(red: 0.5, green: 0.8, blue: 1.0) : .white.opacity(0.85)
                    )
                }
            }
        }
    }

    private func genresSection(game: CatalogGameObject) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SidePanelSectionHeader(icon: "square.grid.2x2.fill", title: "Genres")

            FlowLayout(spacing: 8) {
                ForEach(game.genres, id: \.self) { genre in
                    SidePanelChip(
                        icon: CatalogGenreCopy.icon(genre),
                        text: CatalogGenreCopy.displayName(genre)
                    )
                }
            }
        }
    }

    private func ratingSection(rating: (title: String, descriptors: [String])) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SidePanelSectionHeader(icon: "shield.fill", title: "Age & Content Rating")

            HStack(spacing: 8) {
                SidePanelChip(
                    icon: "exclamationmark.shield.fill",
                    text: rating.title,
                    tintColor: Color.white.opacity(0.1),
                    foregroundColor: .white.opacity(0.9)
                )
            }

            if !rating.descriptors.isEmpty {
                Text(rating.descriptors.joined(separator: " • "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func languagesSection(languages: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SidePanelSectionHeader(icon: "globe", title: "Supported Languages")

            Text(languages.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func descriptionSection(game: CatalogGameObject) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SidePanelSectionHeader(icon: "text.alignleft", title: "About")

            let description = game.shortDescription.isEmpty ? game.longDescription : game.shortDescription
            let resolved = description.isEmpty ? game.gameDescription : description
            Text(resolved.isEmpty ? "No description available." : resolved)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Helpers

    private func formattedReleaseDate(_ raw: String) -> String {
        guard !raw.isEmpty else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let date = formatter.date(from: raw) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        let fullFormatter = ISO8601DateFormatter()
        if let date = fullFormatter.date(from: raw) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        if raw.count >= 4 {
            return String(raw.prefix(4))
        }
        return raw
    }

    private func nvidiaTechItems(for game: CatalogGameObject) -> [(title: String, icon: String)] {
        var items: [(title: String, icon: String)] = []
        var seen = Set<String>()
        for tech in game.nvidiaTech {
            let lower = tech.lowercased()
            if (lower.contains("rtx") || lower.contains("ray")) && seen.insert("rtx").inserted {
                items.append(("Ray Tracing / RTX", "sparkles"))
            } else if lower.contains("dlss") && seen.insert("dlss").inserted {
                items.append(("DLSS", "cpu.fill"))
            } else if lower.contains("reflex") && seen.insert("reflex").inserted {
                items.append(("Reflex", "bolt.fill"))
            } else if lower.contains("hdr") && seen.insert("hdr").inserted {
                items.append(("HDR", "sun.max.fill"))
            }
        }
        return items
    }

    private func storeItems(for game: CatalogGameObject) -> [(title: String, isOwned: Bool, icon: String)] {
        var result: [(title: String, isOwned: Bool, icon: String)] = []
        var seen = Set<String>()

        if !game.variants.isEmpty {
            for variant in game.variants {
                let name = variant.appStoreLabel.isEmpty ? variant.appStore : variant.appStoreLabel
                guard !name.isEmpty else { continue }
                let key = name.lowercased()
                guard seen.insert(key).inserted else { continue }
                let isOwned = variant.inLibrary || variant.librarySelected
                result.append((title: cleanStoreName(name), isOwned: isOwned, icon: storeIconName(for: key)))
            }
        } else {
            for store in game.availableStores {
                guard !store.isEmpty else { continue }
                let key = store.lowercased()
                guard seen.insert(key).inserted else { continue }
                result.append((title: cleanStoreName(store), isOwned: game.isInLibrary, icon: storeIconName(for: key)))
            }
        }
        return result
    }

    private func cleanStoreName(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("steam") { return "Steam" }
        if lower.contains("epic") { return "Epic Games" }
        if lower.contains("xbox") || lower.contains("msstore") || lower.contains("microsoft") { return "Xbox" }
        if lower.contains("ubisoft") || lower.contains("uplay") { return "Ubisoft Connect" }
        if lower.contains("ea") || lower.contains("origin") { return "EA App" }
        if lower.contains("gog") { return "GOG" }
        if lower.contains("battle") || lower.contains("bnet") { return "Battle.net" }
        return raw.capitalized
    }

    private func storeIconName(for lower: String) -> String {
        if lower.contains("steam") { return "gamecontroller.fill" }
        if lower.contains("xbox") { return "gamecontroller" }
        return "cart.fill"
    }

    private func supportedLanguages(for game: CatalogGameObject) -> [String] {
        var langs: [String] = []
        var seen = Set<String>()
        for variant in game.variants {
            for lang in variant.supportedLanguages {
                let cleaned = lang.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !cleaned.isEmpty, seen.insert(cleaned.lowercased()).inserted else { continue }
                langs.append(cleaned)
            }
        }
        return langs
    }

    private func ratingDisplay(for game: CatalogGameObject) -> (title: String, descriptors: [String])? {
        let rating = game.ratingCategoryTitle.isEmpty ? (game.contentRatings.first ?? "") : game.ratingCategoryTitle
        guard !rating.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        var descriptors: [String] = []
        for d in game.ratingDescriptors + game.ratingInteractiveElements {
            let cleaned = d.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty && !descriptors.contains(cleaned) {
                descriptors.append(cleaned)
            }
        }
        return (rating, descriptors)
    }

    private func hasCloudSaves(for game: CatalogGameObject) -> Bool {
        game.variants.contains { $0.cloudSaveSupported } || game.featureLabels.contains { $0.localizedCaseInsensitiveContains("cloud") }
    }

    private func playerModeBadges(for game: CatalogGameObject) -> [(title: String, icon: String)] {
        var badges: [(title: String, icon: String)] = []
        if game.maxOnlinePlayers > 1 {
            badges.append(("\(game.maxOnlinePlayers) Online", "person.3.fill"))
        } else if game.maxOnlinePlayers == 1 {
            badges.append(("Online", "person.fill"))
        }
        if game.maxLocalPlayers > 1 {
            badges.append(("\(game.maxLocalPlayers) Local", "person.2.fill"))
        }
        if !game.playType.isEmpty {
            let cleanType = game.playType.replacingOccurrences(of: "_", with: " ").capitalized
            if !badges.contains(where: { $0.title.localizedCaseInsensitiveContains(cleanType) }) {
                badges.append((cleanType, "person.crop.rectangle.stack.fill"))
            }
        }
        if badges.isEmpty && (game.maxLocalPlayers == 1 || game.maxOnlinePlayers == 0) {
            badges.append(("Single-Player", "person.fill"))
        }
        return badges
    }
}

// MARK: - UI Components

private struct SidePanelSectionHeader: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(0.5)
        }
    }
}

private struct SidePanelChip: View {
    let icon: String?
    let text: String
    var tintColor: Color = .white.opacity(0.08)
    var foregroundColor: Color = .white.opacity(0.88)

    var body: some View {
        HStack(spacing: 5) {
            if let icon = icon, !icon.isEmpty {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(foregroundColor.opacity(0.9))
            }
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tintColor)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
