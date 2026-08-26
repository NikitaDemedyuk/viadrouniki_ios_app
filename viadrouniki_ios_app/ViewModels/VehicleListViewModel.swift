import Foundation
import Observation

@Observable
@MainActor
final class VehicleListViewModel {
    var vehicles: [Vehicle] = []
    var isLoading = false
    var errorMessage: String?
    var sortField: CarSortField = .year
    var sortOrder: SortOrder = .asc

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
                let response = try await APIClient.shared.fetchCars(
                    page: 1,
                    sortBy: sortField,
                    sortOrder: sortOrder
                )
                guard generation == loadGeneration else { return }
                vehicles = response.data
                currentPage = 1
                hasMorePages = response.meta.currentPage < response.meta.lastPage
            } catch {
                guard generation == loadGeneration else { return }
                errorMessage = error.presentableMessage
            }
        } while isReloadPending
    }

    func fetchMoreIfNeeded(currentVehicle: Vehicle) async {
        guard hasMorePages, !isFetchingMore, !isLoading,
            vehicles.last?.id == currentVehicle.id
        else { return }

        isFetchingMore = true
        defer { isFetchingMore = false }

        let generation = loadGeneration
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetchCars(
                page: nextPage,
                sortBy: sortField,
                sortOrder: sortOrder
            )
            guard generation == loadGeneration else { return }
            vehicles.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }
}
