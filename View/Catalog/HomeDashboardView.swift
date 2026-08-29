import SwiftUI

struct HomeDashboardView: View {
    @ObservedObject var viewModel: CatalogViewModel
    @ObservedObject var store: CatalogSelectionStore
    let play: (CatalogGameObject) -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 20) {
                    // UPPER LEFT: Featured Games
                    VStack(spacing: 12) {
                        GameDetailOverlayPanel(
                            game: store.selectedGame,
                            isFavorite: {
                                if let g = store.selectedGame { return viewModel.isFavorite(g) }
                                return false
                            }(),
                            play: { if let g = store.selectedGame { play(g) } },
                            toggleFavorite: {
                                if let g = store.selectedGame {
                                    viewModel.selectGame(g)
                                    viewModel.toggleFavoriteSelectedGame()
                                }
                            }
                        )
                        
                        HStack(spacing: 12) {
                            ForEach(Array(store.games.prefix(5).enumerated()), id: \.element.id) { index, game in
                                GameCardView(
                                    game: game,
                                    isSelected: index == store.selectedIndex,
                                    scale: 0.8,
                                    select: { store.select(at: index) },
                                    launch: { play(game) }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // UPPER RIGHT: Player Stats Widget
                    PlayerStatsWidgetView(statistics: viewModel.playtimeStatistics)
                }

                HStack(alignment: .top, spacing: 20) {
                    // LOWER LEFT: CloudMatch Info
                    CloudMatchWidgetView(selectedRegionUrl: viewModel.selectedSettingsRegionUrl, regionOptions: viewModel.settingsRegionOptions)
                        .frame(maxWidth: .infinity)

                    // LOWER RIGHT: New Additions
                    NewAdditionsWidgetView(games: viewModel.catalogGames, play: play)
                        .frame(width: 300)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 70) // Push below chrome
            .padding(.bottom, 20)
            .background(PixelPatternBackground())
        }
    }
}

struct PixelPatternBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let invader: [[Int]] = [
                    [0,0,1,0,0,0,0,0,1,0,0],
                    [0,0,0,1,0,0,0,1,0,0,0],
                    [0,0,1,1,1,1,1,1,1,0,0],
                    [0,1,1,0,1,1,1,0,1,1,0],
                    [1,1,1,1,1,1,1,1,1,1,1],
                    [1,0,1,1,1,1,1,1,1,0,1],
                    [1,0,1,0,0,0,0,0,1,0,1],
                    [0,0,0,1,1,0,1,1,0,0,0]
                ]
                
                let pixelSize: CGFloat = 8
                let invaderWidth = CGFloat(invader[0].count) * pixelSize
                let invaderHeight = CGFloat(invader.count) * pixelSize
                
                let spacingX: CGFloat = 80
                let spacingY: CGFloat = 80
                
                var path = Path()
                
                for startY in stride(from: 0, to: size.height, by: invaderHeight + spacingY) {
                    for startX in stride(from: 0, to: size.width, by: invaderWidth + spacingX) {
                        for (r, row) in invader.enumerated() {
                            for (c, val) in row.enumerated() {
                                if val == 1 {
                                    let rect = CGRect(
                                        x: startX + CGFloat(c) * pixelSize,
                                        y: startY + CGFloat(r) * pixelSize,
                                        width: pixelSize,
                                        height: pixelSize
                                    )
                                    path.addRect(rect)
                                }
                            }
                        }
                    }
                }
                context.fill(path, with: .color(Color.green.opacity(0.06)))
            }
            .background(Color(red: 0.05, green: 0.06, blue: 0.05)) // Solid dark color
        }
        .ignoresSafeArea()
    }
}

struct PlayerStatsWidgetView: View {
    let statistics: CatalogPlaytimeStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Player Stats")
                .font(.title2).bold()
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                StatRow(label: "Total Sessions", value: "\(statistics.sessionCount)")
                StatRow(label: "Playtime", value: formatDuration(statistics.totalSeconds))
                if !statistics.lastPlayedTitle.isEmpty {
                    StatRow(label: "Last Played", value: statistics.lastPlayedTitle)
                }
                if statistics.longestSessionSeconds > 0 {
                    StatRow(label: "Longest Session", value: formatDuration(statistics.longestSessionSeconds))
                }
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .frame(width: 300)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        if hrs > 0 {
            return "\(hrs)h \(mins)m"
        }
        return "\(mins)m"
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).foregroundStyle(.white).bold()
                .lineLimit(1)
        }
    }
}

struct CloudMatchWidgetView: View {
    let selectedRegionUrl: String
    let regionOptions: [StreamRegionOption]
    
    var currentRegion: StreamRegionOption? {
        if selectedRegionUrl.isEmpty {
            return regionOptions.first(where: { $0.automatic })
        }
        return regionOptions.first(where: { $0.url == selectedRegionUrl })
    }
    
    var bestRegion: StreamRegionOption? {
        regionOptions.filter({ !$0.automatic && $0.latencyMs >= 0 }).min(by: { $0.latencyMs < $1.latencyMs })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CloudMatch Info")
                .font(.title2).bold()
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                StatRow(label: "Current Region", value: currentRegion?.name ?? "Automatic")
                StatRow(label: "Latency", value: currentRegion?.latencyMs ?? -1 >= 0 ? "\(currentRegion!.latencyMs) ms" : "Unknown")
                if let best = bestRegion, currentRegion?.automatic == true {
                    StatRow(label: "Best Available", value: best.name)
                    StatRow(label: "Best Latency", value: "\(best.latencyMs) ms")
                }
            }
            .padding()
            .background(Color.black.opacity(0.4))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct NewAdditionsWidgetView: View {
    let games: [CatalogGameObject]
    let play: (CatalogGameObject) -> Void

    @State private var selectedIndex = 0

    var newGames: [CatalogGameObject] {
        let sorted = games.sorted { $0.releaseDate > $1.releaseDate }
        return Array(sorted.prefix(4))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Additions")
                .font(.title2).bold()
                .foregroundStyle(.white)

            if newGames.isEmpty {
                Text("No new games found.").foregroundStyle(.secondary)
                Spacer()
            } else {
                let safeIndex = selectedIndex < newGames.count ? selectedIndex : 0
                let selectedGame = newGames[safeIndex]
                
                Button(action: { play(selectedGame) }) {
                    VStack(alignment: .leading, spacing: 8) {
                        CatalogRemoteImage(url: URL(string: selectedGame.heroImageUrl.isEmpty ? selectedGame.imageUrl : selectedGame.heroImageUrl), contentMode: .fill)
                            .aspectRatio(16/9, contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 140)
                            .clipped()
                            .cornerRadius(8)
                        
                        Text(selectedGame.title)
                            .font(.headline)
                            .lineLimit(1)
                            .foregroundStyle(.white)
                        
                        Text(selectedGame.genres.joined(separator: ", "))
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                HStack(spacing: 8) {
                    ForEach(Array(newGames.enumerated()), id: \.element.id) { index, game in
                        Button(action: { selectedIndex = index }) {
                            CatalogRemoteImage(url: URL(string: game.heroImageUrl.isEmpty ? game.imageUrl : game.heroImageUrl), contentMode: .fill)
                                .aspectRatio(16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(selectedIndex == index ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}
