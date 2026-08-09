import Foundation

struct Point: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let type: PointType
    let address: String?
    let latitude: String?
    let longitude: String?
    let description: String?
    let mainPhoto: TripPhoto?
    let photos: [PointPhoto]?
    let tripsCount: Int
    let photosCount: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, slug, type, address, latitude, longitude, description, photos
        case mainPhoto = "main_photo"
        case tripsCount = "trips_count"
        case photosCount = "photos_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PointPhoto: Identifiable, Codable, Hashable {
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

extension PointPhoto: PhotoResource {}

struct PointType: Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
}

struct PointMapItem: Identifiable, Codable, Hashable {
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

extension Point {
    init(mapItem: PointMapItem) {
        id = mapItem.id
        name = mapItem.name ?? ""
        slug = mapItem.slug ?? ""
        type = PointType(id: mapItem.type ?? 0, name: "", slug: "")
        address = nil
        latitude = mapItem.latitude.map { "\($0)" }
        longitude = mapItem.longitude.map { "\($0)" }
        description = nil
        mainPhoto = nil
        photos = nil
        tripsCount = 0
        photosCount = 0
        isActive = mapItem.isActive ?? true
        createdAt = .now
        updatedAt = .now
    }

    init(attraction: TripAttraction) {
        id = attraction.attractionId
        name = attraction.name
        slug = attraction.slug
        if let attractionType = attraction.type {
            type = PointType(id: attractionType.id, name: attractionType.name, slug: attractionType.slug)
        } else {
            type = PointType(id: 0, name: "", slug: "")
        }
        address = attraction.address.isEmpty ? nil : attraction.address
        latitude = attraction.latitude.map { "\($0)" }
        longitude = attraction.longitude.map { "\($0)" }
        description = attraction.attractionDescription.isEmpty ? nil : attraction.attractionDescription
        mainPhoto = nil
        photos = nil
        tripsCount = attraction.tripsCount
        photosCount = 0
        isActive = true
        createdAt = .now
        updatedAt = .now
    }
}
