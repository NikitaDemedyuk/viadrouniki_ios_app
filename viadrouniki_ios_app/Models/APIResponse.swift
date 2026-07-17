import Foundation

struct SingleResponse<T: Codable>: Codable {
    let data: T
}

struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let meta: PaginationMeta
}

struct PaginationMeta: Codable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage    = "last_page"
        case perPage     = "per_page"
        case total
    }
}
