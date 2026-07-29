import SwiftUI

struct PhotoHeroView<Photo: PhotoResource>: View {
    let photos: [Photo]?
    let heroURL: URL?
    let placeholderSystemImage: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let height: CGFloat = 280

    var body: some View {
        if let photos, photos.count > 1 {
            gallery(photos.sorted { ($0.isMain == true) && ($1.isMain != true) })
        } else {
            hero(url: heroURL)
        }
    }

    private func gallery(_ photos: [Photo]) -> some View {
        GeometryReader { geometry in
            TabView {
                ForEach(photos) { photo in
                    let url = horizontalSizeClass == .regular ? photo.url : photo.urlMobile
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: height)
                            .clipped()
                    } placeholder: {
                        placeholder
                            .frame(width: geometry.size.width, height: height)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(width: geometry.size.width, height: height)
        }
        .frame(height: height)
    }

    private func hero(url: URL?) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: height)
                    .clipped()
            } placeholder: {
                placeholder
                    .frame(width: geometry.size.width, height: height)
            }
        }
        .frame(height: height)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: placeholderSystemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            )
    }
}
