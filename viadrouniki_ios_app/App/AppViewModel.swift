import Observation

@Observable
final class AppViewModel {
    var isLoggedIn: Bool
    var selectedTab: Int = 0

    /// Mirrors `AppLanguage.current` so SwiftUI observes changes; the static stays
    /// the source of truth because `APIClient` reads it too.
    var language: AppLanguage {
        didSet { AppLanguage.current = language }
    }

    init() {
        isLoggedIn = AuthTokenStore.shared.isLoggedIn
        language = AppLanguage.current
    }

    func login(token: String) {
        AuthTokenStore.shared.token = token
        isLoggedIn = true
        selectedTab = 3
    }

    func logout() {
        AuthTokenStore.shared.logout()
        isLoggedIn = false
        selectedTab = 0
    }
}
