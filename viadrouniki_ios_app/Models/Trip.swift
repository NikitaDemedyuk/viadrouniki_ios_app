import Foundation

struct Trip: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let subtitle: String
    let number: Int
    let slug: String
    let tripDescription: String
    let routeLengthKm: Int?
    let startDate: Date
    let endDate: Date?
    let meetingPoint: String
    let meetingPointLatitude: Double?
    let meetingPointLongitude: Double?
    let meetingTime: String
    let applicationApprovedExtra: String?
    let applicationsDeadline: Date?
    let status: TripStatus
    let isPublic: Bool
    let maxParticipants: Int?
    let currentParticipants: Int
    let attractionsCount: Int
    let applicationsCount: Int?
    let photosCount: Int
    let carsCount: Int
    let rating: Double?
    let ratingsCount: Int
    let organizer: TripOrganizer
    let mainPhoto: TripPhoto?
    let photos: [TripPhoto]?
    let attractions: [TripAttraction]?
    let externalLinks: ExternalLinkList
    let isActive: Bool
    let canAcceptApplications: Bool
    let canSubmitApplication: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, number, slug, status, rating, photos, attractions
        case tripDescription        = "description"
        case externalLinks          = "external_links"
        case routeLengthKm          = "route_length_km"
        case startDate              = "start_date"
        case endDate                = "end_date"
        case meetingPoint           = "meeting_point"
        case meetingPointLatitude   = "meeting_point_latitude"
        case meetingPointLongitude  = "meeting_point_longitude"
        case meetingTime            = "meeting_time"
        case applicationApprovedExtra = "application_approved_extra"
        case applicationsDeadline   = "applications_deadline"
        case isPublic               = "is_public"
        case maxParticipants        = "max_participants"
        case currentParticipants    = "current_participants"
        case attractionsCount       = "attractions_count"
        case applicationsCount      = "applications_count"
        case photosCount            = "photos_count"
        case carsCount              = "cars_count"
        case ratingsCount           = "ratings_count"
        case organizer              = "user"
        case mainPhoto              = "main_photo"
        case isActive               = "is_active"
        case canAcceptApplications  = "can_accept_applications"
        case canSubmitApplication   = "can_submit_application"
        case createdAt              = "created_at"
        case updatedAt              = "updated_at"
    }
}

enum TripStatus: String, Codable {
    case upcoming
    case active
    case completed
    case cancelled
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = TripStatus(rawValue: raw) ?? .unknown
    }
}

struct TripOrganizer: Codable, Hashable {
    let id: Int
    let firstName: String
    let lastName: String
    let instagram: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name, instagram
        case firstName = "first_name"
        case lastName  = "last_name"
    }
}

struct TripPhoto: Identifiable, Codable, Hashable {
    let id: Int
    let mediaId: Int?
    let url: URL
    let urlMobile: URL
    let alt: String?
    let isMain: Bool?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, url, alt
        case mediaId = "media_id"
        case urlMobile = "url_mobile"
        case isMain = "is_main"
        case sortOrder = "sort_order"
    }
}

extension TripPhoto: PhotoResource {}

struct ExternalLink: Codable, Hashable {
    let url: URL
    let label: String
}

/// The API encodes `external_links` inconsistently: `[]`, `[{"url","label"}]`,
/// or a `{"map": "...", "link": "..."}` object with plain URL strings. This
/// normalizes all three shapes to `[ExternalLink]` instead of throwing.
struct ExternalLinkList: Codable, Hashable {
    let items: [ExternalLink]

    var isEmpty: Bool { items.isEmpty }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([ExternalLink].self) {
            items = array
        } else if let dictionary = try? container.decode([String: String].self) {
            items = dictionary.compactMap { key, value in
                URL(string: value).map { ExternalLink(url: $0, label: key) }
            }
        } else {
            items = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(items)
    }
}

struct TripAttraction: Identifiable, Codable, Hashable {
    let tripAttractionId: Int
    let id: Int
    let name: String
    let slug: String
    let address: String
    let attractionDescription: String
    let externalLinks: ExternalLinkList
    let latitude: Double?
    let longitude: Double?
    let visitedAt: Date?
    let visited: Bool
    let sortOrder: Int
    let tripsCount: Int
    let type: AttractionType?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, address, latitude, longitude, visited, type
        case tripAttractionId     = "trip_attraction_id"
        case attractionDescription = "description"
        case externalLinks        = "external_links"
        case visitedAt            = "visited_at"
        case sortOrder            = "sort_order"
        case tripsCount           = "trips_count"
    }
}

struct AttractionType: Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let icon: String?
    let iconMedia: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, icon
        case iconMedia = "icon_media"
    }
}

/// The `trips/{id}/cars` endpoint returns a slimmed-down car shape (no
/// pagination, far fewer fields than `Vehicle`) — kept separate rather than
/// reused so `Vehicle`'s decode isn't weakened for its own endpoints.
struct TripCar: Identifiable, Codable, Hashable {
    let id: Int
    let brand: String
    let model: String
    let year: Int
    let user: TripCarOwner
    let mainPhoto: TripCarPhoto?

    enum CodingKeys: String, CodingKey {
        case id, brand, model, year, user
        case mainPhoto = "main_photo"
    }
}

struct TripCarOwner: Codable, Hashable {
    let id: Int
    let name: String
}

struct TripCarPhoto: Codable, Hashable {
    let id: Int
    let url: URL
}
