import SwiftUI

struct TripDetailView: View {
    let trip: Trip

    @State private var viewModel = TripDetailViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var displayedTrip: Trip {
        viewModel.trip ?? trip
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoSection

                VStack(alignment: .leading, spacing: 20) {
                    if let message = viewModel.errorMessage, viewModel.trip == nil {
                        ErrorBannerView(message: message) {
                            await viewModel.fetch(slug: trip.slug)
                        }
                    }

                    titleSection
                    statsRow

                    if !displayedTrip.meetingPoint.isEmpty {
                        Divider()
                        meetingSection
                    }

                    if !displayedTrip.tripDescription.isEmpty {
                        Divider()
                        descriptionSection(displayedTrip.tripDescription)
                    }

                    if let attractions = displayedTrip.attractions, !attractions.isEmpty {
                        Divider()
                        attractionsSection(attractions)
                    }

                    Divider()
                    carsSection
                }
                .padding()
            }
        }
        .navigationTitle(displayedTrip.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let fetchTrip: Void = viewModel.fetch(slug: trip.slug)
            async let fetchCars: Void = viewModel.fetchCars(tripId: trip.id)
            _ = await (fetchTrip, fetchCars)
        }
    }

    // MARK: - Photo section

    private var photoSection: some View {
        PhotoHeroView(
            photos: displayedTrip.photos,
            heroURL: displayedTrip.mainPhoto?.url(for: horizontalSizeClass),
            placeholderSystemImage: "map"
        )
    }

    // MARK: - Content sections

    private var titleSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayedTrip.title)
                    .font(.title2)
                    .bold()
                if !displayedTrip.subtitle.isEmpty {
                    Text(displayedTrip.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            Label(formattedDateRange, systemImage: "calendar")
            Label("\(displayedTrip.currentParticipants)", systemImage: "person.2")
            Label("\(displayedTrip.attractionsCount)", systemImage: "mappin")
            if let km = displayedTrip.routeLengthKm {
                Label("\(km) km", systemImage: "arrow.triangle.swap")
            }
            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var formattedDateRange: String {
        guard let end = displayedTrip.endDate,
            !Calendar.current.isDate(end, inSameDayAs: displayedTrip.startDate)
        else {
            return displayedTrip.startDate.formatted(.dateTime.day().month(.abbreviated).year())
        }
        let sameYear = Calendar.current.isDate(displayedTrip.startDate, equalTo: end, toGranularity: .year)
        let start = sameYear
            ? displayedTrip.startDate.formatted(.dateTime.day().month(.abbreviated))
            : displayedTrip.startDate.formatted(.dateTime.day().month(.abbreviated).year())
        return "\(start) – \(end.formatted(.dateTime.day().month(.abbreviated).year()))"
    }

    private var meetingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Meeting point")
                .font(.headline)
            Label(displayedTrip.meetingPoint, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
            Label(formattedMeetingTime, systemImage: "clock")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private static let meetingTimeParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        return formatter
    }()

    private var formattedMeetingTime: String {
        guard let time = Self.meetingTimeParser.date(from: displayedTrip.meetingTime) else {
            return displayedTrip.meetingTime
        }
        return time.formatted(.dateTime.hour().minute())
    }

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(text)
                .font(.body)
        }
    }

    private func attractionsSection(_ attractions: [TripAttraction]) -> some View {
        let sortedAttractions = attractions.sorted { $0.sortOrder < $1.sortOrder }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Attractions")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(sortedAttractions.enumerated()), id: \.element.id) { index, attraction in
                    NavigationLink {
                        PointDetailView(point: Point(attraction: attraction))
                    } label: {
                        attractionRow(attraction, position: index + 1)
                    }
                    .buttonStyle(.plain)

                    if index < sortedAttractions.count - 1 {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func attractionRow(_ attraction: TripAttraction, position: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(position)")
                .font(.caption.monospacedDigit().bold())
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color(.systemGray5), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(attraction.name)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !attraction.address.isEmpty {
                    Text(attraction.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if let typeName = attraction.type?.name, !typeName.isEmpty {
                    Text(typeName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private var carsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cars")
                .font(.headline)

            if viewModel.isLoadingCars {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let message = viewModel.carsErrorMessage, viewModel.cars.isEmpty {
                ErrorBannerView(message: message) {
                    await viewModel.fetchCars(tripId: trip.id)
                }
            } else if viewModel.cars.isEmpty {
                Text("No cars linked to this trip yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.cars) { car in
                        NavigationLink {
                            VehicleDetailView(vehicle: Vehicle(tripCar: car))
                        } label: {
                            carRow(car)
                        }
                        .buttonStyle(.plain)

                        if car.id != viewModel.cars.last?.id {
                            Divider()
                                .padding(.leading, 66)
                        }
                    }
                }
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func carRow(_ car: TripCar) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: car.mainPhoto?.url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "car.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(car.brand) \(car.model)")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(String(car.year)) · \(car.user.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
