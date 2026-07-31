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

    func fetch(slug: String) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        do {
            trip = try await APIClient.shared.fetchTrip(slug: slug)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fetchCars(tripId: Int) async {
        guard !isLoadingCars else { return }
        isLoadingCars = true
        carsErrorMessage = nil
        do {
            cars = try await APIClient.shared.fetchTripCars(id: tripId)
        } catch {
            carsErrorMessage = error.localizedDescription
        }
        isLoadingCars = false
    }
}
