import Foundation

/// How a map point is grouped by the filter sheet: under its attraction type,
/// or under the catch-all row for points whose type is missing or unknown to
/// the app.
enum PointFilterKey: Hashable {
    case type(Int)
    case unknown
}

extension Collection<AttractionType> {
    /// The map's default filter selection: every non-amenity type, plus the
    /// unknown-type catch-all.
    var defaultSelectedFilterKeys: Set<PointFilterKey> {
        Set(filter { !$0.isAmenity }.map { PointFilterKey.type($0.id) } + [.unknown])
    }

    /// Every filter key these types can produce, including the unknown-type
    /// catch-all.
    var allFilterKeys: Set<PointFilterKey> {
        Set(map { PointFilterKey.type($0.id) } + [.unknown])
    }
}
