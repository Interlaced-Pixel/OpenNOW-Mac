import SwiftUI

struct GameRailView: View {
    @ObservedObject var store: CatalogSelectionStore
    let launch: (CatalogGameObject) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: 14) {
                        ForEach(Array(store.games.enumerated()), id: \.element.id) { index, game in
                            GameCardView(
                                game: game,
                                isSelected: index == store.selectedIndex,
                                select: { store.select(at: index) },
                                launch: { launch(game) }
                            )
                            .id(CatalogSelectionStore.gameIdentity(game))
                        }
                    }
                    .padding(.horizontal, max(0, geometry.size.width / 2 - 99))
                }
                .onChange(of: store.selectedIndex) { _, newIndex in
                    guard store.games.indices.contains(newIndex) else { return }
                    let identity = CatalogSelectionStore.gameIdentity(store.games[newIndex])
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(identity, anchor: .center)
                    }
                }
                .onAppear {
                    guard store.games.indices.contains(store.selectedIndex) else { return }
                    let identity = CatalogSelectionStore.gameIdentity(store.games[store.selectedIndex])
                    proxy.scrollTo(identity, anchor: .center)
                }
            }
        }
        .frame(height: 150)
    }
}
