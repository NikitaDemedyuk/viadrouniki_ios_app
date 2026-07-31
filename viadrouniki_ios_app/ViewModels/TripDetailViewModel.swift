import Foundation
import Observation

@Observable
@MainActor
final class TripDetailViewModel {
    var trip: Trip?
    var isLoading = false
    var errorMessage: String?

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
}
