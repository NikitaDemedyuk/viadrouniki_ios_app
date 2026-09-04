import SwiftUI

/// What the cars request depends on. Keyed as a single value so a change to any
/// input re-runs the fetch exactly once — the sort field and order previously
/// had a `.task` each, which meant two `fetchInitial()` calls on every appear.
private struct VehiclesRequest: Equatable {
    let sortField: CarSortField
    let sortOrder: SortOrder
    let locale: Locale
}

struct VehicleListView: View {
    @State private var viewModel = VehicleListViewModel()
    /// The API `locale` is part of the request, so a language change
    /// invalidates what's on screen — re-running the fetch is what replaces it.
    @Environment(\.locale) private var locale
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            content
                // Pre-resolved off `appViewModel.language` — see `AppLanguage.localized(_:)`.
                .navigationTitle(appViewModel.language.localized("Cars"))
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
        .task(
            id: VehiclesRequest(
                sortField: viewModel.sortField,
                sortOrder: viewModel.sortOrder,
                locale: locale
            )
        ) { await viewModel.fetchInitial() }
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
        .environment(AppViewModel())
}
