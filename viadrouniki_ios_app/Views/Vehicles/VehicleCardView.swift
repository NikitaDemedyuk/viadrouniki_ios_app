import SwiftUI

struct VehicleCardView: View {
    let vehicle: Vehicle

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: 8) {
                Text(
                    "\(Text("\(vehicle.brand) \(vehicle.model)").font(.headline).foregroundStyle(.primary))\(Text(verbatim: "  \(vehicle.year)").font(.subheadline).foregroundStyle(.secondary))"
                )

                HStack(spacing: 12) {
                    if let name = vehicle.user.name {
                        Label(name, systemImage: "person")
                    }
                    Label("\(vehicle.tripsCount)", systemImage: "map")
                    Image(systemName: vehicle.scheduleIcon)
                        .foregroundStyle(vehicle.scheduleColor)
                        .accessibilityLabel(vehicle.schedule.label)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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
                        Image(systemName: "car")
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
        vehicle.mainPhoto?.url(for: horizontalSizeClass)
    }
}

extension Vehicle {
    var scheduleIcon: String {
        switch schedule {
        case .summer: return "sun.max.fill"
        case .winter: return "snowflake"
        case .unknown: return "calendar"
        }
    }

    var scheduleColor: Color {
        switch schedule {
        case .summer: return .orange
        case .winter: return .blue
        case .unknown: return .secondary
        }
    }
}
