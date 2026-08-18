import Foundation

enum CarSortField: String {
    case year
    case brand = "alphabet"
    case tripsCount = "trips"
}

extension APIClient {
    func fetchCar(id: Int) async throws -> Vehicle {
        let url = baseURL.appending(path: "cars/\(id)")
        let response: SingleResponse<Vehicle> = try await get(url: url)
        return response.data
    }

    func fetchCarTrips(
        id: Int,
        page: Int = 1,
        perPage: Int = 12,
        locale: String = AppLanguage.current.apiLocale
    ) async throws -> PaginatedResponse<Trip> {
        let url =
            baseURL
            .appending(path: "cars/\(id)/trips")
            .appending(queryItems: [
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "locale", value: locale),
                URLQueryItem(name: "page", value: "\(page)"),
            ])
        return try await get(url: url)
    }

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
