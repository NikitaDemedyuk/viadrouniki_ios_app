import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle

    @State private var viewModel = VehicleDetailViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    private var displayedVehicle: Vehicle { viewModel.vehicle ?? vehicle }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoSection

                VStack(alignment: .leading, spacing: 20) {
                    if let message = viewModel.errorMessage, viewModel.vehicle == nil {
                        errorBanner(message: message) {
                            await viewModel.fetch(id: vehicle.id)
                        }
                    }

                    titleSection
                    statsRow
                    Divider()
                    ownerSection

                    if let description = displayedVehicle.description, !description.isEmpty {
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
        .navigationTitle("\(vehicle.brand) \(vehicle.model)")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let fetchVehicle: Void = viewModel.fetch(id: vehicle.id)
            async let fetchTrips: Void = viewModel.fetchTrips(vehicleId: vehicle.id)
            _ = await (fetchVehicle, fetchTrips)
        }
    }

    // MARK: - Photo section

    @ViewBuilder
    private var photoSection: some View {
        if let photos = displayedVehicle.photos, photos.count > 1 {
            let sorted = photos.sorted { ($0.isMain == true) && ($1.isMain != true) }
            galleryView(sorted)
        } else {
            heroImage(url: photoURL(for: displayedVehicle.photos?.first ?? displayedVehicle.mainPhoto))
        }
    }

    private func galleryView(_ photos: [VehiclePhoto]) -> some View {
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
                Image(systemName: "car.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            )
    }

    private func photoURL(for photo: VehiclePhoto?) -> URL? {
        horizontalSizeClass == .regular ? photo?.url : photo?.urlMobile
    }

    // MARK: - Content sections

    private var titleSection: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(
                "\(Text("\(displayedVehicle.brand) \(displayedVehicle.model)").font(.title2).bold().foregroundStyle(.primary))\(Text(verbatim: "  \(displayedVehicle.year)").font(.subheadline).foregroundStyle(.secondary))"
            )
            Spacer()
            if !displayedVehicle.isActive {
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
            Label("\(displayedVehicle.tripsCount) trips", systemImage: "map")
            Label("\(displayedVehicle.photosCount) photos", systemImage: "photo")
            Image(systemName: displayedVehicle.scheduleIcon)
                .foregroundStyle(displayedVehicle.scheduleColor)
                .accessibilityLabel(displayedVehicle.schedule.label)
            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var ownerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Owner")
                .font(.headline)

            if let name = displayedVehicle.user.name {
                HStack(spacing: 6) {
                    Image(systemName: "person")
                        .frame(width: 20)
                    Text(name)
                }
                .font(.subheadline)
            }

            if let instagram = displayedVehicle.user.instagram {
                let handle = instagram.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
                if let url = URL(string: "https://www.instagram.com/\(handle)") {
                    Button {
                        openURL(url)
                    } label: {
                        HStack(spacing: 6) {
                            Image("instagram")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 15, height: 15)
                                .frame(width: 20)
                            Text("@\(handle)")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.pink)
                    }
                }
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
                    await viewModel.fetchTrips(vehicleId: vehicle.id)
                }
            } else if viewModel.trips.isEmpty {
                Text("There aren't any trips with this car right now")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.trips) { trip in
                        TripCardView(trip: trip)
                            .task { await viewModel.fetchMoreTripsIfNeeded(currentTrip: trip, vehicleId: vehicle.id) }
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
        VehicleDetailView(vehicle: Vehicle(
            id: 1,
            userId: 1,
            brand: "Toyota",
            model: "Land Cruiser 200",
            year: 2019,
            description: "A reliable off-road vehicle used for many club expeditions across Belarus and beyond.",
            mainPhoto: nil,
            photos: nil,
            user: VehicleOwner(id: 1, firstName: "Ivan", lastName: "Petrov", instagram: "ivan_travels", name: "Ivan Petrov", telegramUsername: nil),
            photosCount: 42,
            tripsCount: 17,
            isActive: true,
            schedule: .summer,
            canDelete: false,
            createdAt: .now,
            updatedAt: .now
        ))
    }
}
