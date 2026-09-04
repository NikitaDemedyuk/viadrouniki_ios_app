import SwiftUI

/// A compact car row for the Profile tab's "My cars" section.
///
/// Not `VehicleCardView` — that's a 200pt-cover-image card built for a scrolling
/// feed, not a Settings-style inset-grouped list.
struct ProfileCarRow: View {
    let vehicle: Vehicle

    private let thumbnailSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(vehicle.brand) \(vehicle.model)")
                    .font(.body)
                    .foregroundStyle(.primary)
                /// `verbatim` is load-bearing on the year: `Text("\(vehicle.year)")`
                /// takes the `LocalizedStringKey` interpolation path and renders
                /// «1 992» under a Russian locale. `VehicleCardView` sidesteps it
                /// the same way.
                Text(verbatim: "\(vehicle.year)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var thumbnail: some View {
        /// `urlMobile` unconditionally rather than `PhotoResource.url(for:)`:
        /// that helper picks the desktop variant in a regular size class, which
        /// for a 44pt thumbnail means downloading 214 KB where 81 KB would do
        /// (measured on a real car photo). The size class is the right input for
        /// a full-bleed hero, not for this.
        AsyncImage(url: vehicle.mainPhoto?.urlMobile) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "car")
                        .foregroundStyle(.secondary)
                }
        }
        .frame(width: thumbnailSize, height: thumbnailSize)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
