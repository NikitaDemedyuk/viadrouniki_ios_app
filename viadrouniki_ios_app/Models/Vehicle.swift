import Foundation

struct Vehicle: Identifiable, Codable, Hashable {
    let id: Int
    let userId: Int
    let brand: String
    let model: String
    let year: Int
    let description: String?
    let mainPhoto: VehiclePhoto?
    let photos: [VehiclePhoto]?
    let user: VehicleOwner
    let photosCount: Int
    let tripsCount: Int
    let isActive: Bool
    private let rawSchedule: VehicleSchedule?
    let canDelete: Bool
    let createdAt: Date
    let updatedAt: Date

    var schedule: VehicleSchedule { rawSchedule ?? .unknown }

    init(
        id: Int,
        userId: Int,
        brand: String,
        model: String,
        year: Int,
        description: String?,
        mainPhoto: VehiclePhoto?,
        photos: [VehiclePhoto]?,
        user: VehicleOwner,
        photosCount: Int,
        tripsCount: Int,
        isActive: Bool,
        schedule: VehicleSchedule,
        canDelete: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.brand = brand
        self.model = model
        self.year = year
        self.description = description
        self.mainPhoto = mainPhoto
        self.photos = photos
        self.user = user
        self.photosCount = photosCount
        self.tripsCount = tripsCount
        self.isActive = isActive
        self.rawSchedule = schedule
        self.canDelete = canDelete
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, brand, model, year, description
        case rawSchedule = "schedule"
        case userId      = "user_id"
        case mainPhoto   = "main_photo"
        case photos
        case user
        case photosCount = "photos_count"
        case tripsCount  = "trips_count"
        case isActive    = "is_active"
        case canDelete   = "can_delete"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }
}

struct VehiclePhoto: Identifiable, Codable, Hashable {
    let id: Int
    let mediaId: Int?
    let url: URL
    let urlMobile: URL
    let alt: String?
    let isMain: Bool?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, url, alt
        case mediaId     = "media_id"
        case urlMobile   = "url_mobile"
        case isMain      = "is_main"
        case sortOrder   = "sort_order"
    }
}

enum VehicleSchedule: String, Codable {
    case summer
    case winter
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = VehicleSchedule(rawValue: raw) ?? .unknown
    }

    var label: String {
        switch self {
        case .summer: return "Summer"
        case .winter: return "Winter"
        case .unknown: return "Season"
        }
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
