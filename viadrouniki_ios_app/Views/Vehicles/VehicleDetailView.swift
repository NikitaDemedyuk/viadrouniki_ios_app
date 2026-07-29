import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle

    @State private var viewModel = VehicleDetailViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    private var displayedVehicle: Vehicle {
        viewModel.vehicle ?? vehicle
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                photoSection

                VStack(alignment: .leading, spacing: 20) {
                    if let message = viewModel.errorMessage, viewModel.vehicle == nil {
                        ErrorBannerView(message: message) {
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

    private var photoSection: some View {
        PhotoHeroView(
            photos: displayedVehicle.photos,
            heroURL: photoURL(for: displayedVehicle.photos?.first ?? displayedVehicle.mainPhoto),
            placeholderSystemImage: "car.fill"
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
                ErrorBannerView(message: message) {
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
}
