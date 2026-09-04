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

    /// The signed-in user's own cars.
    ///
    /// One request, no pagination state: `per_page` is capped at 100 by the API
    /// (`pagination_max_per_page`) and a user's `car_limit` is 25, so the whole
    /// list fits in a single page. If `meta.currentPage < meta.lastPage` ever
    /// becomes true, this is silently truncating and needs real pagination.
    ///
    /// Lives here rather than in `APIClient+Auth.swift` because it returns
    /// `Vehicle` — keeping every `Vehicle`-returning call in one file matters
    /// more than the `user/` URL prefix.
    func fetchMyCars(perPage: Int = 100) async throws -> PaginatedResponse<Vehicle> {
        let url =
            baseURL
            .appending(path: "user/cars")
            .appending(queryItems: [
                URLQueryItem(name: "per_page", value: "\(perPage)")
            ])
        return try await get(url: url, requiresAuth: true)
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
