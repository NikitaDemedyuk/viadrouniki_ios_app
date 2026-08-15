import Foundation

struct AttractionType: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let icon: String?
    let iconMedia: String?
    let color: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, icon, color
        case iconMedia = "icon_media"
        case sortOrder = "sort_order"
    }

    /// The API groups core attraction categories under `sort_order < 100` and
    /// amenities (gas stations, cafes) at `sort_order >= 100`. Amenities are
    /// listed separately in the filter sheet and hidden from the map until the
    /// user opts in, matching the web app.
    var isAmenity: Bool {
        (sortOrder ?? 0) >= 100
    }
}

extension Collection<AttractionType> {
    /// Sorted the way the API intends them to be listed. `sort_order` has ties
    /// in practice, so `id` breaks them — otherwise row order would vary between
    /// presentations of the filter sheet.
    var sortedForDisplay: [AttractionType] {
        sorted { ($0.sortOrder ?? 0, $0.id) < ($1.sortOrder ?? 0, $1.id) }
    }
}
