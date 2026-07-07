import Foundation

enum SortOrder: String {
    case asc
    case desc
}

extension APIClient {
    func fetchTrips(
        page: Int = 1,
        perPage: Int = 18,
        sortOrder: SortOrder = .desc,
        locale: String = "ru"
    ) async throws -> PaginatedResponse<Trip> {
        let url = baseURL
            .appending(path: "trips")
            .appending(queryItems: [
                URLQueryItem(name: "page",       value: "\(page)"),
                URLQueryItem(name: "per_page",   value: "\(perPage)"),
                URLQueryItem(name: "sort_by",    value: "start_date"),
                URLQueryItem(name: "sort_order", value: sortOrder.rawValue),
                URLQueryItem(name: "locale",     value: locale)
            ])
        return try await get(url: url)
    }
}
