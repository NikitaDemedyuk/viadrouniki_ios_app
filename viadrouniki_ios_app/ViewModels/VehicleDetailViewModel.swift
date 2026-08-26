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

    private var loadGeneration = 0
    private var currentTripsPage = 1
    private var hasMoreTrips = true
    private var isFetchingMoreTrips = false
    private var tripsLoadGeneration = 0

    func fetch(id: Int) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        loadGeneration += 1
        let generation = loadGeneration
        errorMessage = nil
        do {
            let response = try await APIClient.shared.fetchCar(id: id)
            guard generation == loadGeneration else { return }
            vehicle = response
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }

    func fetchTrips(vehicleId: Int) async {
        guard !isLoadingTrips else { return }
        isLoadingTrips = true
        defer { isLoadingTrips = false }

        isFetchingMoreTrips = false
        tripsLoadGeneration += 1
        let generation = tripsLoadGeneration
        tripsErrorMessage = nil
        do {
            let response = try await APIClient.shared.fetchCarTrips(id: vehicleId, page: 1)
            guard generation == tripsLoadGeneration else { return }
            trips = response.data
            currentTripsPage = 1
            hasMoreTrips = response.meta.currentPage < response.meta.lastPage
        } catch {
            guard generation == tripsLoadGeneration else { return }
            tripsErrorMessage = error.presentableMessage
        }
    }

    func fetchMoreTripsIfNeeded(currentTrip: Trip, vehicleId: Int) async {
        guard hasMoreTrips, !isFetchingMoreTrips, !isLoadingTrips,
            trips.last?.id == currentTrip.id
        else { return }

        isFetchingMoreTrips = true
        defer { isFetchingMoreTrips = false }

        let generation = tripsLoadGeneration
        let nextPage = currentTripsPage + 1

        do {
            let response = try await APIClient.shared.fetchCarTrips(id: vehicleId, page: nextPage)
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
