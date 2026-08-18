import SwiftUI

struct VehicleListView: View {
    @State private var viewModel = VehicleListViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            content
                .navigationTitle("Cars")
                .navigationDestination(for: Vehicle.self) { vehicle in
                    VehicleDetailView(vehicle: vehicle)
                }
                .refreshable { await viewModel.fetchInitial() }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Picker("Sort by", selection: $viewModel.sortField) {
                                Label("Year", systemImage: "calendar")
                                    .tag(CarSortField.year)
                                Label("Brand", systemImage: "car")
                                    .tag(CarSortField.brand)
                                Label("Trips", systemImage: "map")
                                    .tag(CarSortField.tripsCount)
                            }
                            .pickerStyle(.inline)

                            Picker("Order", selection: $viewModel.sortOrder) {
                                Label("Ascending", systemImage: "arrow.up")
                                    .tag(SortOrder.asc)
                                Label("Descending", systemImage: "arrow.down")
                                    .tag(SortOrder.desc)
                            }
                            .pickerStyle(.inline)
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                        }
                    }
                }
        }
        .task(id: viewModel.sortField) { await viewModel.fetchInitial() }
        .task(id: viewModel.sortOrder) { await viewModel.fetchInitial() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.vehicles.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.vehicles.isEmpty {
            ContentUnavailableView(
                "Failed to load vehicles",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            vehicleList
        }
    }

    private var vehicleList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.vehicles) { vehicle in
                    NavigationLink(value: vehicle) {
                        VehicleCardView(vehicle: vehicle)
                    }
                    .buttonStyle(.plain)
                    .task { await viewModel.fetchMoreIfNeeded(currentVehicle: vehicle) }
                }
            }
            .padding()
        }
    }
}

#Preview {
    VehicleListView()
}
