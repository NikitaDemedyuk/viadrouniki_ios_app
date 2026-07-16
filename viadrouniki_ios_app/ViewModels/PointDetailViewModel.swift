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

    private var currentTripsPage = 1
    private var hasMoreTrips = true
    private var isFetchingMoreTrips = false

    func fetch(slug: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            point = try await APIClient.shared.fetchAttraction(slug: slug)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchTrips(slug: String) async {
        guard !isLoadingTrips else { return }
        isLoadingTrips = true
        tripsErrorMessage = nil
        do {
            let response = try await APIClient.shared.fetchAttractionTrips(slug: slug, page: 1)
            trips = response.data
            currentTripsPage = 1
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            tripsErrorMessage = error.localizedDescription
        }
        isLoadingTrips = false
    }

    func fetchMoreTripsIfNeeded(currentTrip: Trip, slug: String) async {
        guard hasMoreTrips, !isFetchingMoreTrips, !isLoadingTrips,
              trips.last?.id == currentTrip.id
        else { return }

        isFetchingMoreTrips = true
        let nextPage = currentTripsPage + 1

        do {
            let response = try await APIClient.shared.fetchAttractionTrips(slug: slug, page: nextPage)
            trips.append(contentsOf: response.data)
            currentTripsPage = nextPage
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            tripsErrorMessage = error.localizedDescription
        }

        isFetchingMoreTrips = false
    }
}
