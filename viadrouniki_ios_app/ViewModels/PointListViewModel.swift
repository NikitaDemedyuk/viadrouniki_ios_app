import Foundation
import Observation

@Observable
@MainActor
final class PointListViewModel {
    var points: [Point] = []
    var mapPoints: [PointMapItem] = []
    var searchText: String = ""
    var isLoading = false
    var isLoadingMap = false
    var errorMessage: String?
    var mapErrorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true
    private var isFetchingMore = false
    private var lastFetchedSearch: String = ""

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
            errorMessage = error.localizedDescription
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
            errorMessage = error.localizedDescription
        }

        isFetchingMore = false
    }

    func fetchMapPoints() async {
        guard mapPoints.isEmpty, !isLoadingMap else { return }
        isLoadingMap = true
        mapErrorMessage = nil
        do {
            mapPoints = try await APIClient.shared.fetchAttractionsMap()
        } catch {
            mapErrorMessage = error.localizedDescription
        }
        isLoadingMap = false
    }
}
