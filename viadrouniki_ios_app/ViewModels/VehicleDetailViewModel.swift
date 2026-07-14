import Foundation
import Observation

@Observable
@MainActor
final class VehicleDetailViewModel {
    var vehicle: Vehicle?
    var isLoading = false
    var errorMessage: String?

    var trips: [Trip] = []
    var isLoadingTrips = false
    var tripsErrorMessage: String?

    private var currentTripsPage = 1
    private var hasMoreTrips = true
    private var isFetchingMoreTrips = false

    func fetch(id: Int) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            vehicle = try await APIClient.shared.fetchCar(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchTrips(vehicleId: Int) async {
        guard !isLoadingTrips else { return }
        isLoadingTrips = true
        tripsErrorMessage = nil
        do {
            let response = try await APIClient.shared.fetchCarTrips(id: vehicleId, page: 1)
            trips = response.data
            currentTripsPage = 1
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            tripsErrorMessage = error.localizedDescription
        }
        isLoadingTrips = false
    }

    func fetchMoreTripsIfNeeded(currentTrip: Trip, vehicleId: Int) async {
        guard hasMoreTrips, !isFetchingMoreTrips, !isLoadingTrips,
            trips.last?.id == currentTrip.id
        else { return }

        isFetchingMoreTrips = true
        let nextPage = currentTripsPage + 1

        do {
            let response = try await APIClient.shared.fetchCarTrips(id: vehicleId, page: nextPage)
            trips.append(contentsOf: response.data)
            currentTripsPage = nextPage
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            tripsErrorMessage = error.localizedDescription
        }

        isFetchingMoreTrips = false
    }
}
