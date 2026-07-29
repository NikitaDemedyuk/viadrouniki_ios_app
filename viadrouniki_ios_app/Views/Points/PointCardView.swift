import SwiftUI

struct PointCardView: View {
    let point: Point

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: 6) {
                Text(point.name)
                    .font(.headline)

                if let address = point.address, !address.isEmpty {
                    Label(address, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let lat = point.latitude, let lon = point.longitude {
                    Label("\(lat), \(lon)", systemImage: "location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var coverImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: photoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 200)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "mappin.circle")
                            .foregroundStyle(.secondary)
                    )
                    .frame(width: geometry.size.width, height: 200)
            }
        }
        .frame(height: 200)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            )
        )
    }

    private var photoURL: URL? {
        horizontalSizeClass == .regular
            ? point.mainPhoto?.url : point.mainPhoto?.urlMobile
    }
}
