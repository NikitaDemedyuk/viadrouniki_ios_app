import CoreLocation
import MapKit
import SwiftUI

private enum DisplayMode: String {
    case list, map
}

/// What the points request depends on. Keyed as a single value so a change to
/// either input re-runs the fetch exactly once, rather than two `.task`s racing
/// to call `fetchInitial()`.
private struct PointsRequest: Equatable {
    let search: String
    let locale: Locale
}

struct PointsView: View {
    @State private var viewModel = PointListViewModel()
    @State private var displayMode: DisplayMode = .list
    @State private var selectedMapPoint: PointMapItem?
    @State private var isFilterPresented = false
    @Environment(\.locale) private var locale

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Group {
                if displayMode == .map {
                    content
                        .toolbar { displayModeButton }
                } else {
                    content
                        .navigationTitle("Points")
                        .searchable(
                            text: $viewModel.searchText,
                            prompt: "Search points"
                        )
                        .toolbar { displayModeButton }
                        .refreshable { await viewModel.fetchInitial() }
                }
            }
            .navigationDestination(for: Point.self) { point in
                PointDetailView(point: point)
            }
        }
        .task(id: PointsRequest(search: viewModel.searchText, locale: locale)) {
            if !viewModel.searchText.isEmpty {
                try? await Task.sleep(for: .milliseconds(400))
            }
            await viewModel.fetchInitial()
        }
    }

    @ToolbarContentBuilder
    private var displayModeButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                displayMode = displayMode == .list ? .map : .list
            } label: {
                Image(systemName: displayMode == .list ? "map" : "list.bullet")
            }
            .accessibilityLabel(
                displayMode == .list
                    ? Text("Switch to map") : Text("Switch to list")
            )
        }
    }

    @ViewBuilder
    private var content: some View {
        if displayMode == .map {
            mapView
        } else if viewModel.isLoading, viewModel.points.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.points.isEmpty {
            ContentUnavailableView(
                "Failed to load points",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if viewModel.points.isEmpty {
            ContentUnavailableView(
                "No points found",
                systemImage: "mappin.slash",
                description: viewModel.searchText.isEmpty
                    ? Text("No points available")
                    : Text("Try a different search")
            )
        } else {
            pointList
        }
    }

    private var mapView: some View {
        Map(
            initialPosition: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: 53.7,
                        longitude: 27.95
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 5.0,
                        longitudeDelta: 5.0
                    )
                )
            ),
            selection: $selectedMapPoint
        ) {
            ForEach(viewModel.filteredMapPoints) { point in
                if let lat = point.latitude, let lon = point.longitude,
                   let slug = point.slug, !slug.isEmpty
                {
                    let attractionType = viewModel.attractionType(for: point)
                    Marker(
                        // A `String` expression, so this takes Marker's
                        // StringProtocol overload and is never looked up in the
                        // catalog — correct, the API already localized it.
                        point.name ?? "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        )
                    )
                    .tint(attractionType?.parsedColor ?? .red)
                    .tag(point)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task(id: locale) { await viewModel.fetchMapPoints() }
        .navigationDestination(item: $selectedMapPoint) { mapPoint in
            PointDetailView(point: Point(mapItem: mapPoint))
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.canFilterMapPoints {
                Button {
                    isFilterPresented = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.title3)
                        .padding(14)
                        .glassEffect(in: .circle)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isFilterPresented) {
            PointsFilterSheet(
                attractionTypes: Array(viewModel.attractionTypesById.values),
                selectedFilterKeys: $viewModel.selectedFilterKeys
            )
        }
        .overlay(alignment: .bottom) {
            if let error = viewModel.mapErrorMessage {
                VStack(spacing: 6) {
                    Text(error)
                        .font(.caption)
                    Button("Retry") {
                        Task { await viewModel.fetchMapPoints() }
                    }
                    .font(.caption.bold())
                }
                .padding(8)
                .background(
                    .regularMaterial,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .padding(.bottom, 100)
            }
        }
    }

    private var pointList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.points) { point in
                    NavigationLink(value: point) {
                        PointCardView(point: point)
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.fetchMoreIfNeeded(
                            currentPoint: point
                        )
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    PointsView()
}
