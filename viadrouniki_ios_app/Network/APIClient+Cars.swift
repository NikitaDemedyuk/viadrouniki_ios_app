import Foundation

enum CarSortField: String {
    case year
    case brand = "alphabet"
    case tripsCount = "trips"
}

extension APIClient {
    func fetchCars(
        page: Int,
        perPage: Int = 18,
        sortBy: CarSortField = .year,
        sortOrder: SortOrder = .asc
    ) async throws -> PaginatedResponse<Vehicle> {
        let url =
            baseURL
            .appending(path: "cars")
            .appending(queryItems: [
                URLQueryItem(name: "sort_by", value: sortBy.rawValue),
                URLQueryItem(name: "sort_order", value: sortOrder.rawValue),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "page", value: "\(page)"),
            ])
        return try await get(url: url)
    }
}
