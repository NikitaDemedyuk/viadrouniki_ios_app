import Foundation

struct Vehicle: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let brand: String
    let model: String
    let year: Int
    let description: String?
    let mainPhoto: TripPhoto?
    let user: VehicleOwner
    let photosCount: Int
    let tripsCount: Int
    let isActive: Bool
    let schedule: String?
    let canDelete: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, brand, model, year, description, schedule
        case userId      = "user_id"
        case mainPhoto   = "main_photo"
        case user
        case photosCount = "photos_count"
        case tripsCount  = "trips_count"
        case isActive    = "is_active"
        case canDelete   = "can_delete"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

struct VehicleOwner: Codable, Hashable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let instagram: String?
    let name: String?
    let telegramUsername: String?

    enum CodingKeys: String, CodingKey {
        case id, name, instagram
        case firstName        = "first_name"
        case lastName         = "last_name"
        case telegramUsername = "telegram_username"
    }
}
