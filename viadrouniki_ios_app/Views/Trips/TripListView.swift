import SwiftUI

struct TripListView: View {
    @State private var viewModel = TripListViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Trips")
                .navigationDestination(for: Trip.self) { trip in
                    TripDetailView(trip: trip)
                }
                .refreshable { await viewModel.fetchInitial() }
        }
        .task { await viewModel.fetchInitial() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.trips.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.trips.isEmpty {
            ContentUnavailableView(
                "Failed to load trips",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            tripList
        }
    }

    private var tripList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.trips) { trip in
                    NavigationLink(value: trip) {
                        TripCardView(trip: trip)
                    }
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.fetchMoreIfNeeded(currentTrip: trip)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    TripListView()
}
