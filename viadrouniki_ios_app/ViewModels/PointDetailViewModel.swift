import Foundation
import Observation

@Observable
@MainActor
final class PointDetailViewModel {
    var point: Point?
    var isLoading = false
    var errorMessage: String?

    var trips: [Trip] = []
    var isLoadingTrips = false
    var tripsErrorMessage: String?

    private var loadGeneration = 0
    private var currentTripsPage = 1
    private var hasMoreTrips = true
    private var isFetchingMoreTrips = false
    private var tripsLoadGeneration = 0

    func fetch(slug: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        loadGeneration += 1
        let generation = loadGeneration
        errorMessage = nil
        do {
            let response = try await APIClient.shared.fetchAttraction(slug: slug)
            guard generation == loadGeneration else { return }
            point = response
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }

    func fetchTrips(slug: String) async {
        guard !isLoadingTrips else { return }
        isLoadingTrips = true
        defer { isLoadingTrips = false }

        isFetchingMoreTrips = false
        tripsLoadGeneration += 1
        let generation = tripsLoadGeneration
        tripsErrorMessage = nil
        do {
            let response = try await APIClient.shared.fetchAttractionTrips(slug: slug, page: 1)
            guard generation == tripsLoadGeneration else { return }
            trips = response.data
            currentTripsPage = 1
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            guard generation == tripsLoadGeneration else { return }
            tripsErrorMessage = error.presentableMessage
        }
    }

    func fetchMoreTripsIfNeeded(currentTrip: Trip, slug: String) async {
        guard hasMoreTrips, !isFetchingMoreTrips, !isLoadingTrips,
              trips.last?.id == currentTrip.id
        else { return }

        isFetchingMoreTrips = true
        defer { isFetchingMoreTrips = false }

        let generation = tripsLoadGeneration
        tripsErrorMessage = nil
        let nextPage = currentTripsPage + 1

        do {
            let response = try await APIClient.shared.fetchAttractionTrips(slug: slug, page: nextPage)
            guard generation == tripsLoadGeneration else { return }
            trips.append(contentsOf: response.data)
            currentTripsPage = nextPage
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            guard generation == tripsLoadGeneration else { return }
            tripsErrorMessage = error.presentableMessage
        }
    }
}
