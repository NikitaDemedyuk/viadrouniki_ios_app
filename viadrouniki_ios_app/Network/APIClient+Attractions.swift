import Foundation

extension APIClient {
    func fetchAttractions(
        page: Int,
        perPage: Int = 20,
        search: String = "",
        locale: String = "ru",
        isActive: String = "active"
    ) async throws -> PaginatedResponse<Point> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "is_active", value: isActive),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "page", value: "\(page)"),
        ]
        if !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        let url = baseURL
            .appending(path: "attractions")
            .appending(queryItems: queryItems)
        return try await get(url: url)
    }

    func fetchAttractionsMap(
        locale: String = "ru",
        isActive: String = "active"
    ) async throws -> [PointMapItem] {
        let url = baseURL
            .appending(path: "attractions/map")
            .appending(queryItems: [
                URLQueryItem(name: "locale", value: locale),
                URLQueryItem(name: "is_active", value: isActive),
            ])
        return try await get(url: url)
    }
}
