import Observation
import Foundation

@Observable
@MainActor
final class TripListViewModel {
    var trips: [Trip] = []
    var isLoading = false
    var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true
    private var isFetchingMore = false

    func fetchInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.fetchTrips(page: 1)
            trips = response.data
            currentPage = 1
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.presentableMessage
        }

        isLoading = false
    }

    func fetchMoreIfNeeded(currentTrip: Trip) async {
        guard hasMorePages,
              !isFetchingMore,
              trips.last?.id == currentTrip.id else { return }

        isFetchingMore = true
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetchTrips(page: nextPage)
            trips.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.presentableMessage
        }

        isFetchingMore = false
    }
}
