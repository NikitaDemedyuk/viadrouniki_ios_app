import Foundation

/// `auth/me` wraps its payload in `{"user": ...}`, not the `{"data": ...}` that
/// `SingleResponse<T>` models — a fourth envelope shape for this API. Kept
/// private and local to the one endpoint that uses it, rather than adding a
/// one-off to `Models/APIResponse.swift` beside the genuinely shared envelopes.
private struct CurrentUserResponse: Decodable {
    let user: AppUser
}

extension APIClient {
    func fetchCurrentUser() async throws -> AppUser {
        let url = baseURL.appending(path: "auth/me")
        let response: CurrentUserResponse = try await get(url: url, requiresAuth: true)
        return response.user
    }
}
