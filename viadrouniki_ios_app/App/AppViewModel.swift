import Observation

@Observable
final class AppViewModel {
    var isLoggedIn: Bool
    var selectedTab: Int = 0

    init() {
        isLoggedIn = AuthTokenStore.shared.isLoggedIn
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
