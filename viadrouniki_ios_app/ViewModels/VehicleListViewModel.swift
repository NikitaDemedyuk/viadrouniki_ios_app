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

    func fetchInitial() async {
        guard !isLoading else { return }
        isLoading = true
        isFetchingMore = false
        errorMessage = nil

        do {
            let response = try await APIClient.shared.fetchCars(
                page: 1,
                sortBy: sortField,
                sortOrder: sortOrder
            )
            vehicles = response.data
            currentPage = 1
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchMoreIfNeeded(currentVehicle: Vehicle) async {

        guard hasMorePages, !isFetchingMore, !isLoading,
            vehicles.last?.id == currentVehicle.id
        else { return }

        isFetchingMore = true
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetchCars(
                page: nextPage,
                sortBy: sortField,
                sortOrder: sortOrder
            )
            vehicles.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isFetchingMore = false
    }
}
