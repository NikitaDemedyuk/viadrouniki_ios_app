import Observation

@Observable
final class AppViewModel {
    var isLoggedIn: Bool

    init() {
        isLoggedIn = AuthTokenStore.shared.isLoggedIn
    }

    func login(token: String) {
        AuthTokenStore.shared.token = token
        isLoggedIn = true
    }

    func logout() {
        AuthTokenStore.shared.logout()
        isLoggedIn = false
    }
}
