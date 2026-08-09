import SwiftUI

struct PointDetailView: View {
    let point: Point

    @State private var viewModel = PointDetailViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var displayedPoint: Point {
        viewModel.point ?? point
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoSection

                VStack(alignment: .leading, spacing: 20) {
                    if let message = viewModel.errorMessage, viewModel.point == nil {
                        ErrorBannerView(message: message) {
                            await viewModel.fetch(slug: point.slug)
                        }
                    }

                    titleSection
                    statsRow

                    if let address = displayedPoint.address, !address.isEmpty {
                        Divider()
                        addressSection(address)
                    }

                    if let description = displayedPoint.description, !description.isEmpty {
                        Divider()
                        descriptionSection(description)
                    }

                    Divider()
                    tripsSection
                }
                .padding()
            }
        }
        .navigationTitle(displayedPoint.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Trip.self) { trip in
            TripDetailView(trip: trip)
        }
        .task {
            async let fetchPoint: Void = viewModel.fetch(slug: point.slug)
            async let fetchTrips: Void = viewModel.fetchTrips(slug: point.slug)
            _ = await (fetchPoint, fetchTrips)
        }
    }

    // MARK: - Photo section

    private var photoSection: some View {
        PhotoHeroView(
            photos: displayedPoint.photos,
            heroURL: heroPhotoURL,
            placeholderSystemImage: "mappin.circle"
        )
    }

    private var heroPhotoURL: URL? {
        displayedPoint.mainPhoto?.url(for: horizontalSizeClass)
            ?? displayedPoint.photos?.first?.url(for: horizontalSizeClass)
    }

    // MARK: - Content sections

    private var titleSection: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayedPoint.name)
                    .font(.title2)
                    .bold()
                Text(displayedPoint.type.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !displayedPoint.isActive {
                Text("Inactive")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(Capsule())
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            Label("\(displayedPoint.tripsCount) trips", systemImage: "map")
            Label("\(displayedPoint.photosCount) photos", systemImage: "photo")
            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func addressSection(_ address: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(.headline)
            Label(address, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
            if let lat = displayedPoint.latitude, let lon = displayedPoint.longitude {
                Label("\(lat), \(lon)", systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func descriptionSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(text)
                .font(.body)
        }
    }

    private var tripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trips")
                .font(.headline)

            if viewModel.isLoadingTrips {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let message = viewModel.tripsErrorMessage, viewModel.trips.isEmpty {
                ErrorBannerView(message: message) {
                    await viewModel.fetchTrips(slug: point.slug)
                }
            } else if viewModel.trips.isEmpty {
                Text("There aren't any trips to this point yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.trips) { trip in
                        NavigationLink(value: trip) {
                            TripCardView(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .task {
                            await viewModel.fetchMoreTripsIfNeeded(currentTrip: trip, slug: point.slug)
                        }
                    }
                }

                if let message = viewModel.tripsErrorMessage, let lastTrip = viewModel.trips.last {
                    ErrorBannerView(message: message) {
                        await viewModel.fetchMoreTripsIfNeeded(currentTrip: lastTrip, slug: point.slug)
                    }
                }
            }
        }
    }
}
