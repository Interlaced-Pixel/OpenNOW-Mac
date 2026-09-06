import SwiftUI

struct FavoriteLimitReplacementOverlay: View {
    @ObservedObject var viewModel: CatalogViewModel
    let candidateGame: CatalogGameObject

    @State private var hoveredGameId: String? = nil

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.cancelFavoriteReplacement()
                }

            // Modal Card
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().background(Color.white.opacity(0.12))

                candidatePreview
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                favoritesList
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                Divider().background(Color.white.opacity(0.12))
                footer
            }
            .frame(width: 560)
            .background(Design.Catalog.inspector)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 30, y: 12)
        }
        .onKeyPress(.escape) {
            viewModel.cancelFavoriteReplacement()
            return .handled
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Design.Catalog.action)

            VStack(alignment: .leading, spacing: 2) {
                Text("Favorites Limit Reached (5/5)")
                    .font(.nvidia(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text("You can keep up to 5 favorites. Select a game to replace:")
                    .font(.nvidia(size: 12, weight: .regular))
                    .foregroundStyle(Design.Text.secondary)
            }

            Spacer()

            Button {
                viewModel.cancelFavoriteReplacement()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Design.Text.tertiary)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close without replacing")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    // MARK: - Candidate Game Preview
    private var candidatePreview: some View {
        HStack(spacing: 12) {
            CatalogRemoteImage(url: URL(string: candidateGame.bestStorePickerPosterURL), contentMode: .fill)
                .frame(width: 36, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Design.Catalog.action.opacity(0.6), lineWidth: 1.5)
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("NEW FAVORITE")
                        .font(.nvidia(size: 9, weight: .bold))
                        .foregroundStyle(Design.Catalog.action)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Design.Catalog.action.opacity(0.14))
                        .clipShape(Capsule())

                    let candidateSubtitle = !candidateGame.publisherName.isEmpty ? candidateGame.publisherName : candidateGame.developerName
                    if !candidateSubtitle.isEmpty {
                        Text(candidateSubtitle)
                            .font(.nvidia(size: 10, weight: .medium))
                            .foregroundStyle(Design.Text.tertiary)
                    }
                }

                Text(candidateGame.title.isEmpty ? "Selected Game" : candidateGame.title)
                    .font(.nvidia(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Selectable Favorites List
    private var favoritesList: some View {
        VStack(spacing: 8) {
            ForEach(Array(viewModel.favoriteGames.prefix(CatalogViewModel.maxFavoritesLimit).enumerated()), id: \.element.id) { index, game in
                favoriteRow(game: game, slot: index + 1)
            }
        }
    }

    private func favoriteRow(game: CatalogGameObject, slot: Int) -> some View {
        let isHovered = hoveredGameId == game.id

        return Button {
            viewModel.replaceFavorite(existingGame: game, with: candidateGame)
        } label: {
            HStack(spacing: 12) {
                CatalogRemoteImage(url: URL(string: game.bestStorePickerPosterURL), contentMode: .fill)
                    .frame(width: 36, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("SLOT \(slot)")
                            .font(.nvidia(size: 9, weight: .bold))
                            .foregroundStyle(Design.Text.tertiary)

                        let rowSubtitle = !game.publisherName.isEmpty ? game.publisherName : game.developerName
                        if !rowSubtitle.isEmpty {
                            Text("•  \(rowSubtitle)")
                                .font(.nvidia(size: 10, weight: .medium))
                                .foregroundStyle(Design.Text.muted)
                        }
                    }

                    Text(game.title.isEmpty ? "Game" : game.title)
                        .font(.nvidia(size: 13, weight: .bold))
                        .foregroundStyle(isHovered ? .white : Design.Text.primary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                    Text("Replace")
                        .font(.nvidia(size: 12, weight: .bold))
                }
                .foregroundStyle(isHovered ? .black : Design.Catalog.action)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isHovered ? Design.Catalog.action : Design.Catalog.action.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Design.Catalog.action.opacity(isHovered ? 1.0 : 0.4), lineWidth: 1)
                )
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovered ? Color.white.opacity(0.07) : Color.white.opacity(0.025))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isHovered ? Design.Catalog.action.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredGameId = hovering ? game.id : nil
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack {
            Spacer()

            Button("Cancel") {
                viewModel.cancelFavoriteReplacement()
            }
            .buttonStyle(.plain)
            .font(.nvidia(size: 13, weight: .medium))
            .foregroundStyle(Design.Text.secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}
