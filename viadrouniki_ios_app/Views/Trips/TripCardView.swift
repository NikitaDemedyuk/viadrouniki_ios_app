import SwiftUI

struct TripCardView: View {
    let trip: Trip

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    /// `formatted(_:)` returns a plain `String`, so it would otherwise use
    /// `Locale.current` (the device) instead of the app's selected language.
    @Environment(\.locale) private var locale

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
                    if let applicationsCount = trip.applicationsCount {
                        Label("\(applicationsCount)", systemImage: "car")
                    }
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
        trip.mainPhoto?.url(for: horizontalSizeClass)
    }

    private var formattedDate: String {
        let dayMonthYear = Date.FormatStyle.dateTime.day().month(.abbreviated).year().locale(locale)
        guard let end = trip.endDate,
            !Calendar.current.isDate(end, inSameDayAs: trip.startDate)
        else {
            return trip.startDate.formatted(dayMonthYear)
        }
        let sameYear = Calendar.current.isDate(trip.startDate, equalTo: end, toGranularity: .year)
        let start = sameYear
            ? trip.startDate.formatted(.dateTime.day().month(.abbreviated).locale(locale))
            : trip.startDate.formatted(dayMonthYear)
        return "\(start) – \(end.formatted(dayMonthYear))"
    }

}
