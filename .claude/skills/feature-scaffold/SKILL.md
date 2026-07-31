---
name: feature-scaffold
description: Scaffold a new list-based feature (Model → APIClient extension → ViewModel → List/Card Views) for viadrouniki_ios_app, following the same vertical-slice pattern already used by Trips, Points, and Vehicles. Use this when the user asks to add a new tab, section, or resource-backed feature — e.g. "add a Garages feature", "scaffold a new tab for X", "create a list screen backed by /v1/<endpoint>". Not for one-off screens with no paginated API-backed list.
---

# Feature scaffold — viadrouniki_ios_app

Every existing feature (Trips, Points, Vehicles) is the same 4-file vertical slice:

```
Models/<Domain>.swift                        struct, Codable, CodingKeys
Network/APIClient+<Domain>s.swift             extension APIClient { func fetch<Domain>s(...) }
ViewModels/<Domain>ListViewModel.swift        @Observable @MainActor final class
Views/<Domain>s/<Domain>ListView.swift        ScrollView + LazyVStack + pagination
Views/<Domain>s/<Domain>CardView.swift        row/card shown in the list
```

Read `references/templates.md` before writing anything — it has the exact code templates with the project's real conventions, including one **intentional deviation** from what you'll see in `TripCardView.swift`/`VehicleCardView.swift` on `develop` (explained there). Don't pattern-match those two files directly for the cover-image code; use the template.

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new files placed in the right folder are picked up automatically. No manual project-file editing needed, just build to verify (`xcodebuild -scheme viadrouniki_ios_app -destination 'generic/platform=iOS Simulator' build`).

## Before generating anything, gather:

1. **Domain name**, singular, PascalCase (e.g. `Garage`). Plural for endpoint/file naming follows Swift pluralization (`Garages`) unless the user says otherwise.
2. **API endpoint path** (e.g. `garages`) and **response field list** with their JSON key names — ask for a sample JSON response if the user has one; don't guess field names or invent fields that weren't mentioned.
3. Whether the list needs **sorting options** (like Vehicles' brand/year/trips sort menu) or is a **fixed sort** (like Trips' `start_date desc`).
4. Whether entries have a **photo** (most do — drives whether `CardView` needs a `coverImage`).
5. Whether a **detail screen** is in scope for this pass, or just the list (default: list only, matching how Trips/Points shipped before Vehicles later got a detail page — don't build a detail view unless asked).

Do not invent an endpoint shape from nothing. If the user hasn't given you field names, ask — a scaffold with fabricated fields is worse than no scaffold, because it'll silently fail to decode against the real API.

## Generation steps

1. **Model** (`Models/<Domain>.swift`): struct conforming to `Identifiable, Codable, Hashable`. `CodingKeys` mapping every snake_case JSON field to camelCase. If there's a pagination wrapper needed, **do not redeclare `PaginatedResponse`/`PaginationMeta`** — they already exist at the top level (currently declared in `Models/Trip.swift`, used module-wide by Points and Vehicles too). Just return `PaginatedResponse<Domain>` from the fetch function.
2. **Network** (`Network/APIClient+<Domain>s.swift`): one `extension APIClient` with a `fetch<Domain>s(page:perPage:sortOrder:locale:)` async throws function, matching the query-param and `locale: String = "ru"` pattern in `APIClient+Trips.swift`/`APIClient+Cars.swift`. Reuse `SortOrder` (declared in `APIClient+Trips.swift`) instead of redeclaring it.
3. **ViewModel** (`ViewModels/<Domain>ListViewModel.swift`): `@Observable @MainActor final class` with `fetchInitial()` / `fetchMoreIfNeeded(current:)` following the exact guard-and-pagination-state pattern in `TripListViewModel.swift` (see template — the guard conditions and `isFetchingMore` flag matter, don't simplify them away).
4. **Views**: `<Domain>ListView.swift` (loading/error/content states, `.refreshable`, `ScrollView` + `LazyVStack`) and `<Domain>CardView.swift` (card layout — use the template's `coverImage`, not a copy of `TripCardView`'s).
5. **Build** to confirm it compiles before telling the user it's done.
6. **Tell the user, don't do it yourself**: wiring the new `<Domain>ListView` into `App/ContentView.swift`'s `TabView` is a product decision (tab order, icon, whether it needs auth-gating like the Profile/Login tab does) — surface the snippet to add and let them place it, rather than editing `ContentView.swift` unprompted.

## What NOT to do

- Don't add a detail view, search, or map view unless asked — Trips and Points shipped for a long time as list-only.
- Don't introduce a new `Service` protocol/DI layer — every existing feature calls `APIClient.shared` directly from the ViewModel. That's a known architecture inconsistency (flagged in past reviews) but scaffolding a new pattern for one feature would make the codebase less consistent, not more. Match what's there.
- Don't add unit tests unless asked — there is no test target in this project yet.
- Don't guess the icon/SF Symbol for the tab — ask, or leave a `TODO` placeholder in the snippet you hand back for `ContentView.swift`.
