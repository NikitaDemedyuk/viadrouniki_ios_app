import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var user: AppUser?
    var isLoading = false
    var errorMessage: String?

    /// Set when the stored token was rejected. The View turns this into a
    /// `logout()`; the ViewModel can't, because `AppViewModel` sits above it
    /// and the dependency direction points downward only.
    private(set) var sessionExpired = false

    private var loadGeneration = 0

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

    /// Bumps the generation so an in-flight response can't land after sign-out.
    func clear() {
        loadGeneration += 1
        user = nil
        errorMessage = nil
        sessionExpired = false
    }
}
