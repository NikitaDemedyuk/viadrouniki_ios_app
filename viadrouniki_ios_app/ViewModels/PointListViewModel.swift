import Foundation
import Observation

@Observable
@MainActor
final class PointListViewModel {
    var points: [Point] = []
    var mapPoints: [PointMapItem] = []
    var attractionTypesById: [Int: AttractionType] = [:]
    /// Which groups of points the map shows. Set to the default selection
    /// (see `defaultSelectedFilterKeys`) once types load.
    var selectedFilterKeys: Set<PointFilterKey> = []
    var searchText: String = ""
    var isLoading = false
    var isLoadingMap = false
    var errorMessage: String?
    var mapErrorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true
    private var isFetchingMore = false
    private var lastFetchedSearch: String = ""
    /// The API locale `mapPoints` was fetched for, set only on success.
    ///
    /// The map's `.task` re-runs every time the map reappears, so something has
    /// to stop a list↔map toggle from refetching. Guarding on `mapPoints.isEmpty`
    /// did that but also blocked the refetch a language change needs — and
    /// treated "loaded, but the server returned nothing" as "never loaded".
    private var loadedMapLocale: String?

    func fetchInitial() async {
        isFetchingMore = false
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        lastFetchedSearch = searchText

        do {
            let response = try await APIClient.shared.fetchAttractions(
                page: 1,
                search: searchText
            )
            points = response.data
            currentPage = 1
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.presentableMessage
        }

        isLoading = false
    }

    func fetchMoreIfNeeded(currentPoint: Point) async {
        guard hasMorePages, !isFetchingMore, !isLoading,
              points.last?.id == currentPoint.id
        else { return }

        isFetchingMore = true
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetchAttractions(
                page: nextPage,
                search: lastFetchedSearch
            )
            guard isFetchingMore else { return }
            points.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.presentableMessage
        }

        isFetchingMore = false
    }

    func fetchMapPoints() async {
        let locale = AppLanguage.current.apiLocale
        guard loadedMapLocale != locale, !isLoadingMap else { return }
        isLoadingMap = true
        mapErrorMessage = nil

        // Fetched together so markers are only ever built once already tinted:
        // MapKit's SwiftUI wrapper doesn't reliably re-tint a marker it has
        // already materialized once attraction types arrive a moment later.
        async let typesTask: [AttractionType] = (try? APIClient.shared.fetchAttractionTypes()) ?? []
        do {
            let points = try await APIClient.shared.fetchAttractionsMap()
            let types = await typesTask
            // `uniquingKeysWith:` rather than `uniqueKeysWithValues:`: the latter
            // traps on a duplicate id, which is server-controlled input.
            attractionTypesById = Dictionary(
                types.map { ($0.id, $0) },
                uniquingKeysWith: { _, latest in latest }
            )
            selectedFilterKeys = types.defaultSelectedFilterKeys
            mapPoints = points
            loadedMapLocale = locale
        } catch {
            mapErrorMessage = error.presentableMessage
        }

        isLoadingMap = false
    }

    /// Whether the filter affordance has anything to offer. False when the
    /// attraction-types request failed, in which case every point is shown
    /// untinted and there is nothing to filter by.
    var canFilterMapPoints: Bool {
        !attractionTypesById.isEmpty
    }

    /// The point's attraction type, or nil if it carries no type or one the
    /// types endpoint didn't return.
    func attractionType(for point: PointMapItem) -> AttractionType? {
        point.type.flatMap { attractionTypesById[$0] }
    }

    func filterKey(for point: PointMapItem) -> PointFilterKey {
        attractionType(for: point).map { .type($0.id) } ?? .unknown
    }

    var filteredMapPoints: [PointMapItem] {
        mapPoints.filter { selectedFilterKeys.contains(filterKey(for: $0)) }
    }
}
