import Foundation

extension APIClient {
    func fetchAttraction(
        slug: String,
        locale: String = AppLanguage.current.apiLocale
    ) async throws -> Point {
        let url =
            baseURL
                .appending(path: "attractions/slug/\(slug)")
                .appending(queryItems: [
                    URLQueryItem(name: "locale", value: locale),
                ])
        let response: SingleResponse<Point> = try await get(url: url)
        return response.data
    }

    func fetchAttractionTrips(
        slug: String,
        page: Int = 1,
        perPage: Int = 15,
        locale: String = AppLanguage.current.apiLocale
    ) async throws -> PaginatedResponse<Trip> {
        let url =
            baseURL
                .appending(path: "attractions/slug/\(slug)/trips")
                .appending(queryItems: [
                    URLQueryItem(name: "per_page", value: "\(perPage)"),
                    URLQueryItem(name: "locale", value: locale),
                    URLQueryItem(name: "page", value: "\(page)"),
                ])
        return try await get(url: url)
    }

    func fetchAttractions(
        page: Int,
        perPage: Int = 20,
        search: String = "",
        locale: String = AppLanguage.current.apiLocale,
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
        let url =
            baseURL
                .appending(path: "attractions")
                .appending(queryItems: queryItems)
        return try await get(url: url)
    }

    func fetchAttractionsMap(
        locale: String = AppLanguage.current.apiLocale,
        isActive: String = "active"
    ) async throws -> [PointMapItem] {
        let url =
            baseURL
                .appending(path: "attractions/map")
                .appending(queryItems: [
                    URLQueryItem(name: "locale", value: locale),
                    URLQueryItem(name: "is_active", value: isActive),
                ])
        return try await get(url: url)
    }

    func fetchAttractionTypes(locale: String = AppLanguage.current.apiLocale) async throws -> [AttractionType] {
        let url =
            baseURL
                .appending(path: "attraction-types")
                .appending(queryItems: [
                    URLQueryItem(name: "locale", value: locale),
                ])
        let response: SingleResponse<[AttractionType]> = try await get(url: url)
        return response.data
    }
}
