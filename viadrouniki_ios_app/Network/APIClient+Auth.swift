import Foundation

extension APIClient {
    func fetchCurrentUser() async throws -> AppUser {
        try await get(url: baseURL.appending(path: "auth/me"), requiresAuth: true)
    }
}
