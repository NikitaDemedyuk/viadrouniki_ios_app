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
    private var loadGeneration = 0
    private var isReloadPending = false

    func fetchInitial() async {
        guard !isLoading else {
            isReloadPending = true
            return
        }
        isLoading = true
        defer { isLoading = false }

        repeat {
            isReloadPending = false
            isFetchingMore = false
            loadGeneration += 1
            let generation = loadGeneration
            errorMessage = nil

            do {
                let response = try await APIClient.shared.fetchTrips(page: 1)
                guard generation == loadGeneration else { return }
                trips = response.data
                currentPage = 1
                hasMorePages = response.meta.currentPage < response.meta.lastPage
            } catch {
                guard generation == loadGeneration else { return }
                errorMessage = error.presentableMessage
            }
        } while isReloadPending
    }

    func fetchMoreIfNeeded(currentTrip: Trip) async {
        guard hasMorePages,
              !isFetchingMore,
              !isLoading,
              trips.last?.id == currentTrip.id else { return }

        isFetchingMore = true
        defer { isFetchingMore = false }

        let generation = loadGeneration
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetchTrips(page: nextPage)
            guard generation == loadGeneration else { return }
            trips.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }
}
