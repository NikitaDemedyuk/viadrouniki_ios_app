import Foundation

struct Point: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let type: PointType
    let address: String?
    let latitude: String?
    let longitude: String?
    let mainPhoto: TripPhoto?
    let tripsCount: Int
    let photosCount: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, slug, type, address, latitude, longitude
        case mainPhoto = "main_photo"
        case tripsCount = "trips_count"
        case photosCount = "photos_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PointType: Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
}

struct PointMapItem: Identifiable, Codable {
    let id: Int
    let name: String?
    let slug: String?
    let type: Int?
    let latitude: Double?
    let longitude: Double?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, type, latitude, longitude
        case isActive = "is_active"
    }
}
