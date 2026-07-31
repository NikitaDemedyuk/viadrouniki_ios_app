# Scaffold templates

Placeholders: `<Domain>` = PascalCase singular (`Garage`), `<domain>` = camelCase singular (`garage`), `<domains>` = camelCase plural (`garages`), `<endpoint>` = API path segment (`garages`).

Fill in real fields from the API response the user gave you — the field lists below are illustrative only, not something to copy verbatim.

---

## 1. Model — `Models/<Domain>.swift`

```swift
import Foundation

struct <Domain>: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let mainPhoto: <Domain>Photo?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title
        case mainPhoto = "main_photo"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct <Domain>Photo: Codable, Hashable {
    let id: Int
    let url: URL
    let urlMobile: URL
    let alt: String?

    enum CodingKeys: String, CodingKey {
        case id, url, alt
        case urlMobile = "url_mobile"
    }
}
```

Notes:
- `PaginatedResponse<T>` / `PaginationMeta` already exist (declared in `Trip.swift`) — do not redeclare them here.
- If the domain doesn't have a photo, drop `<Domain>Photo` and the `mainPhoto` field, and skip `coverImage` in the CardView template below entirely (don't render a placeholder for a field that doesn't exist).
- Only include an enum-with-fallback (like `TripStatus`/`VehicleSchedule`) if the API actually has a status/category-style string field. Don't add one speculatively.

---

## 2. Network — `Network/APIClient+<Domain>s.swift`

```swift
import Foundation

extension APIClient {
    func fetch<Domain>s(
        page: Int = 1,
        perPage: Int = 18,
        sortOrder: SortOrder = .desc,
        locale: String = "ru"
    ) async throws -> PaginatedResponse<<Domain>> {
        let url = baseURL
            .appending(path: "<endpoint>")
            .appending(queryItems: [
                URLQueryItem(name: "page",       value: "\(page)"),
                URLQueryItem(name: "per_page",   value: "\(perPage)"),
                URLQueryItem(name: "sort_order", value: sortOrder.rawValue),
                URLQueryItem(name: "locale",     value: locale)
            ])
        return try await get(url: url)
    }
}
```

`SortOrder` is already declared in `APIClient+Trips.swift` — reuse it. If the feature needs a custom sort field enum (like `CarSortField` for Vehicles), model it the same way: a `String`-backed enum with `rawValue`s matching the API's expected query values, declared at the top of this file.

---

## 3. ViewModel — `ViewModels/<Domain>ListViewModel.swift`

```swift
import Observation
import Foundation

@Observable
@MainActor
final class <Domain>ListViewModel {
    var <domains>: [<Domain>] = []
    var isLoading = false
    var errorMessage: String?

    private var currentPage = 1
    private var hasMorePages = true
    private var isFetchingMore = false

    func fetchInitial() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response = try await APIClient.shared.fetch<Domain>s(page: 1)
            <domains> = response.data
            currentPage = 1
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func fetchMoreIfNeeded(current<Domain>: <Domain>) async {
        guard hasMorePages,
              !isFetchingMore,
              !isLoading,
              <domains>.last?.id == current<Domain>.id
        else { return }

        isFetchingMore = true
        let nextPage = currentPage + 1

        do {
            let response = try await APIClient.shared.fetch<Domain>s(page: nextPage)
            <domains>.append(contentsOf: response.data)
            currentPage = nextPage
            hasMorePages = response.meta.currentPage < response.meta.lastPage
        } catch {
            errorMessage = error.localizedDescription
        }

        isFetchingMore = false
    }
}
```

The `!isLoading` guard in `fetchMoreIfNeeded` is in `VehicleListViewModel` but missing from `TripListViewModel` on `develop` — include it. It prevents a pagination fetch from racing an in-flight initial/refresh fetch.

---

## 4. List View — `Views/<Domain>s/<Domain>ListView.swift`

```swift
import SwiftUI

struct <Domain>ListView: View {
    @State private var viewModel = <Domain>ListViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("<Domain>s")
                .refreshable { await viewModel.fetchInitial() }
        }
        .task { await viewModel.fetchInitial() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.<domains>.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.<domains>.isEmpty {
            ContentUnavailableView(
                "Failed to load <domains>",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else {
            <domain>List
        }
    }

    private var <domain>List: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.<domains>) { <domain> in
                    <Domain>CardView(<domain>: <domain>)
                        .task { await viewModel.fetchMoreIfNeeded(current<Domain>: <domain>) }
                }
            }
            .padding()
        }
    }
}

#Preview {
    <Domain>ListView()
}
```

If the feature needs a detail screen later (not part of this scaffold unless asked), the pattern to follow is `VehicleListView`'s `NavigationLink(value:) + .navigationDestination(for:)` — wrap the card in `NavigationLink(value: <domain>) { <Domain>CardView(...) }.buttonStyle(.plain)` instead of a bare card.

---

## 5. Card View — `Views/<Domain>s/<Domain>CardView.swift`

```swift
import SwiftUI

struct <Domain>CardView: View {
    let <domain>: <Domain>

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            coverImage

            VStack(alignment: .leading, spacing: 8) {
                Text(<domain>.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    // IMPORTANT: this uses GeometryReader with an explicit width, unlike
    // TripCardView/the pre-fix VehicleCardView on develop. AsyncImage +
    // .aspectRatio(contentMode: .fill) with only a fixed height (no width)
    // can report an ideal width *larger* than the available column for
    // wide/panoramic photos, pushing the whole card wider than the screen
    // and silently eating its horizontal padding. Confirmed as a real bug
    // in this app (see feature/vehicle-page history) — don't "simplify"
    // this back to a plain `.frame(height: 200)`.
    private var coverImage: some View {
        GeometryReader { geometry in
            AsyncImage(url: photoURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: 200)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    )
                    .frame(width: geometry.size.width, height: 200)
            }
        }
        .frame(height: 200)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 12,
                topTrailingRadius: 12
            )
        )
    }

    private var photoURL: URL? {
        horizontalSizeClass == .regular
            ? <domain>.mainPhoto?.url : <domain>.mainPhoto?.urlMobile
    }
}
```

If the model has no photo field, delete `coverImage` and `photoURL` entirely and just keep the text `VStack` — don't render a placeholder image box for data that doesn't exist.

## 6. Tab wiring snippet (hand to the user, don't apply yourself)

```swift
<Domain>ListView()
    .tabItem { Label("<Domain>s", systemImage: "TODO_pick_sf_symbol") }
    .tag(TODO_next_available_tag)
```

`App/ContentView.swift`'s `TabView` currently has tags 0–3 (Trips, Points, Vehicles, Profile/Login). Ask the user where the new tab should go and what SF Symbol fits, rather than guessing.
