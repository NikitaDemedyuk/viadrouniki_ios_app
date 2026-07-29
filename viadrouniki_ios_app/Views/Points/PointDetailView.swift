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
                        errorBanner(message: message) {
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

                    if !viewModel.isLoadingTrips {
                        Divider()
                        tripsSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle(displayedPoint.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let fetchPoint: Void = viewModel.fetch(slug: point.slug)
            async let fetchTrips: Void = viewModel.fetchTrips(slug: point.slug)
            _ = await (fetchPoint, fetchTrips)
        }
    }

    // MARK: - Photo section

    @ViewBuilder
    private var photoSection: some View {
        if let photos = displayedPoint.photos, photos.count > 1 {
            let sorted = photos.sorted { ($0.isMain == true) && ($1.isMain != true) }
            galleryView(sorted)
        } else {
            heroImage(url: heroPhotoURL)
        }
    }

    private func galleryView(_ photos: [PointPhoto]) -> some View {
        GeometryReader { geometry in
            TabView {
                ForEach(photos) { photo in
                    let url = horizontalSizeClass == .regular ? photo.url : photo.urlMobile
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 280)
                            .clipped()
                    } placeholder: {
                        photoPlaceholder
                            .frame(width: geometry.size.width, height: 280)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(width: geometry.size.width, height: 280)
        }
        .frame(height: 280)
    }

    private func heroImage(url: URL?) -> some View {
        GeometryReader { geometry in
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 280)
                    .clipped()
            } placeholder: {
                photoPlaceholder
                    .frame(width: geometry.size.width, height: 280)
            }
        }
        .frame(height: 280)
    }

    private var photoPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "mappin.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            )
    }

    private var heroPhotoURL: URL? {
        photoURL(for: displayedPoint.mainPhoto) ?? photoURL(for: displayedPoint.photos?.first)
    }

    private func photoURL(for photo: TripPhoto?) -> URL? {
        horizontalSizeClass == .regular ? photo?.url : photo?.urlMobile
    }

    private func photoURL(for photo: PointPhoto?) -> URL? {
        horizontalSizeClass == .regular ? photo?.url : photo?.urlMobile
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

            if let message = viewModel.tripsErrorMessage, viewModel.trips.isEmpty {
                errorBanner(message: message) {
                    await viewModel.fetchTrips(slug: point.slug)
                }
            } else if viewModel.trips.isEmpty {
                Text("There aren't any trips to this point yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.trips) { trip in
                        TripCardView(trip: trip)
                            .task {
                                await viewModel.fetchMoreTripsIfNeeded(currentTrip: trip, slug: point.slug)
                            }
                    }
                }

                if let message = viewModel.tripsErrorMessage, let lastTrip = viewModel.trips.last {
                    errorBanner(message: message) {
                        await viewModel.fetchMoreTripsIfNeeded(currentTrip: lastTrip, slug: point.slug)
                    }
                }
            }
        }
    }

    private func errorBanner(message: String, retry: @escaping () async -> Void) -> some View {
        HStack {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Retry") {
                Task { await retry() }
            }
            .font(.footnote)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        PointDetailView(
            point: Point(
                id: 20,
                name: "Костёл святого Антония",
                slug: "kostel-svyatogo-antoniya",
                type: PointType(id: 2, name: "Костел", slug: "cathedral"),
                address: "",
                latitude: "53.88548330",
                longitude: "28.60884870",
                description: "Костел в Рованичах возведен в начале 19 века.",
                mainPhoto: nil,
                photos: nil,
                tripsCount: 2,
                photosCount: 1,
                isActive: true,
                createdAt: .now,
                updatedAt: .now
            )
        )
    }
}
