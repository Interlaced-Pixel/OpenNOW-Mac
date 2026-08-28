import SwiftUI

struct GameRailView: View {
    @ObservedObject var store: CatalogSelectionStore
    let launch: (CatalogGameObject) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .bottom, spacing: 14) {
                        ForEach(Array(store.games.enumerated()), id: \.offset) { index, game in
                            GameCardView(
                                game: game,
                                isSelected: index == store.selectedIndex,
                                select: { store.select(at: index) },
                                launch: { launch(game) }
                            )
                            .id(CatalogSelectionStore.gameIdentity(game))
                        }
                    }
                    .scrollTargetLayout()
                }
                .safeAreaPadding(.horizontal, max(0, geometry.size.width / 2 - 99))
                .scrollTargetBehavior(.viewAligned)
                .onChange(of: store.selectedIndex) { _, newIndex in
                    if store.games.indices.contains(newIndex) {
                        let identity = CatalogSelectionStore.gameIdentity(store.games[newIndex])
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(identity, anchor: .center)
                        }
                    }
                }
                .onAppear {
                    if store.games.indices.contains(store.selectedIndex) {
                        let identity = CatalogSelectionStore.gameIdentity(store.games[store.selectedIndex])
                        proxy.scrollTo(identity, anchor: .center)
                    }
                }
            }
        }
        .frame(height: 150)
    }
}
