import SwiftUI

struct TripCardView: View {
    let trip: Trip

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: 8) {

                Text(trip.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if !trip.subtitle.isEmpty {
                    Text(trip.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 12) {
                    Label(formattedDate, systemImage: "calendar")
                    Label("\(trip.applicationsCount)", systemImage: "car")
                    Label("\(trip.attractionsCount)", systemImage: "mappin")

                    if let km = trip.routeLengthKm {
                        Label("\(km) km", systemImage: "arrow.triangle.swap")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }

    private var coverImage: some View {
        AsyncImage(url: photoURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
        .frame(height: 200)
        .clipped()
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            )
        )
    }

    private var photoURL: URL? {
        horizontalSizeClass == .regular
            ? trip.mainPhoto?.url : trip.mainPhoto?.urlMobile
    }

    private var formattedDate: String {
        guard let end = trip.endDate,
            !Calendar.current.isDate(end, inSameDayAs: trip.startDate)
        else {
            return trip.startDate.formatted(.dateTime.day().month(.abbreviated).year())
        }
        let sameYear = Calendar.current.isDate(trip.startDate, equalTo: end, toGranularity: .year)
        let start = sameYear
            ? trip.startDate.formatted(.dateTime.day().month(.abbreviated))
            : trip.startDate.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(start) – \(end.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

}
