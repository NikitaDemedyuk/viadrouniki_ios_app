import Foundation
import Observation

@Observable
@MainActor
final class TripDetailViewModel {
    var trip: Trip?
    var isLoading = false
    var errorMessage: String?

    var cars: [TripCar] = []
    var isLoadingCars = false
    var carsErrorMessage: String?

    private var loadGeneration = 0
    private var carsLoadGeneration = 0

    func fetch(slug: String) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        loadGeneration += 1
        let generation = loadGeneration
        errorMessage = nil
        do {
            let response = try await APIClient.shared.fetchTrip(slug: slug)
            guard generation == loadGeneration else { return }
            trip = response
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }

    func fetchCars(tripId: Int) async {
        guard !isLoadingCars else { return }
        isLoadingCars = true
        defer { isLoadingCars = false }

        carsLoadGeneration += 1
        let generation = carsLoadGeneration
        carsErrorMessage = nil
        do {
            let response = try await APIClient.shared.fetchTripCars(id: tripId)
            guard generation == carsLoadGeneration else { return }
            cars = response
        } catch {
            guard generation == carsLoadGeneration else { return }
            carsErrorMessage = error.presentableMessage
        }
    }
}
