import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var user: AppUser?
    var isLoading = false
    var errorMessage: String?

    var cars: [Vehicle] = []
    var isLoadingCars = false
    var carsErrorMessage: String?

    /// Set when the stored token was rejected by *either* request. The View
    /// turns this into a `logout()`; the ViewModel can't, because `AppViewModel`
    /// sits above it and the dependency direction points downward only.
    ///
    /// One flag covers both fetches: they share a single token, so they fail
    /// together and setting it twice is harmless.
    ///
    /// Deliberately *not* reset at the top of `load()`/`loadCars()`. Those two
    /// run concurrently, so a reset in either would race to clear a 401 the
    /// other had already recorded. `clear()` is the only thing that lowers it,
    /// and the View's sign-out path always reaches `clear()` — flipping
    /// `isLoggedIn` re-fires the `.task` with the new key.
    private(set) var sessionExpired = false

    private var loadGeneration = 0
    private var carsLoadGeneration = 0

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        loadGeneration += 1
        let generation = loadGeneration
        errorMessage = nil

        do {
            let response = try await APIClient.shared.fetchCurrentUser()
            guard generation == loadGeneration else { return }
            user = response
        } catch APIError.unauthorized {
            guard generation == loadGeneration else { return }
            /// Not an error to display: the token is stale, so the screen falls
            /// back to the signed-out banner rather than a dead end.
            user = nil
            errorMessage = nil
            sessionExpired = true
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = error.presentableMessage
        }
    }

    /// Same shape as `load()`, against its own generation counter — the two
    /// requests are independent and one failing must not blank the other.
    func loadCars() async {
        guard !isLoadingCars else { return }
        isLoadingCars = true
        defer { isLoadingCars = false }

        carsLoadGeneration += 1
        let generation = carsLoadGeneration
        carsErrorMessage = nil

        do {
            let response = try await APIClient.shared.fetchMyCars()
            guard generation == carsLoadGeneration else { return }
            cars = response.data
        } catch APIError.unauthorized {
            guard generation == carsLoadGeneration else { return }
            cars = []
            carsErrorMessage = nil
            sessionExpired = true
        } catch {
            guard generation == carsLoadGeneration else { return }
            carsErrorMessage = error.presentableMessage
        }
    }

    /// Bumps both generations so an in-flight response can't land after sign-out.
    func clear() {
        loadGeneration += 1
        carsLoadGeneration += 1
        user = nil
        errorMessage = nil
        cars = []
        carsErrorMessage = nil
        sessionExpired = false
    }
}
