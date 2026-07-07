import Foundation

final class AuthTokenStore {
    static let shared = AuthTokenStore()
    private let tokenKey = "auth_token"
    private init() {}

    var token: String? {
        get { KeychainStore.read(key: tokenKey) }
        set {
            if let value = newValue {
                KeychainStore.save(key: tokenKey, value: value)
            } else {
                KeychainStore.delete(key: tokenKey)
            }
        }
    }

    var isLoggedIn: Bool { token != nil }

    func logout() {
        token = nil
    }
}
