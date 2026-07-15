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
    let applicationsCount: Int
    let photosCount: Int
    let carsCount: Int
    let rating: Double?
    let ratingsCount: Int
    let organizer: TripOrganizer
    let mainPhoto: TripPhoto?
    let isActive: Bool
    let canAcceptApplications: Bool
    let canSubmitApplication: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, number, slug, status, rating
        case tripDescription        = "description"
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
    let url: URL
    let urlMobile: URL
    let alt: String?

    enum CodingKeys: String, CodingKey {
        case id, url, alt
        case urlMobile = "url_mobile"
    }
}
