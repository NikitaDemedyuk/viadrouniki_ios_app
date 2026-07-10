import CoreLocation
import MapKit
import SwiftUI

private enum DisplayMode: String {
    case list, map
}

struct PointsView: View {
    @State private var viewModel = PointListViewModel()
    @State private var displayMode: DisplayMode = .list

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
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
        .task(id: viewModel.searchText) {
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
                displayMode == .list ? "Switch to map" : "Switch to list"
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
                description: Text(
                    viewModel.searchText.isEmpty
                        ? "No points available" : "Try a different search"
                )
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
            )
        ) {
            ForEach(viewModel.mapPoints) { point in
                if let lat = point.latitude, let lon = point.longitude {
                    Marker(
                        point.name ?? "",
                        coordinate: CLLocationCoordinate2D(
                            latitude: lat,
                            longitude: lon
                        )
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .task { await viewModel.fetchMapPoints() }
        .overlay(alignment: .bottomTrailing) {
            Button {
                // TODO: open filter sheet
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.title3)
                    .padding(14)
                    .glassEffect(in: .circle)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 40)
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
                    PointCardView(point: point)
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
