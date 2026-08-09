# viadrouniki_ios_app

SwiftUI client for the viadrouniki.by travel API (`https://api.viadrouniki.by/v1`).

These are the project invariants — facts that hold whether or not a skill was invoked.
Skills under `.claude/skills/` cover *procedures*; this file covers *state*. When the two
disagree, this file wins, and the skill should be corrected.

## Build settings

Read from `viadrouniki_ios_app.xcodeproj/project.pbxproj` (identical in Debug and Release,
no `.xcconfig` overrides):

| Setting | Value |
|---|---|
| `IPHONEOS_DEPLOYMENT_TARGET` | `26.5` |
| `SWIFT_VERSION` | `5.0` (Swift 5 language mode) |
| `SWIFT_STRICT_CONCURRENCY` | not set — defaults to `minimal` |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` |

Two consequences worth internalizing:

- **This is not Swift 6 language mode.** Data-race safety is *not* compiler-enforced —
  strict concurrency is at `minimal`. Concurrency bugs must be caught by reading the code,
  not by trusting the build. A green build proves much less here than it would under Swift 6.
- **Default actor isolation is `MainActor`.** Every unannotated type is implicitly
  main-actor-isolated. The explicit `@MainActor` on each ViewModel is therefore redundant
  (harmless, and kept for clarity), and `APIClient` — a plain `final class` with no
  annotation — is implicitly MainActor-isolated too.

Deployment target is iOS 26.5, so current-generation APIs are available unconditionally and
no availability checks are needed. Note that some existing code predates this and still uses
older equivalents (e.g. `ContentView` uses `.tabItem`/`.tag` rather than `Tab`).

## Building

```bash
xcodebuild -scheme viadrouniki_ios_app -destination 'generic/platform=iOS Simulator' build
```

Single target (`viadrouniki_ios_app`, an application). **There is no test target** — do not
write unit tests or suggest test files until one is added.

The project uses `PBXFileSystemSynchronizedRootGroup`: new `.swift` files dropped into the
right folder are picked up automatically, with no `project.pbxproj` editing.

## Architecture

MVVM with the Observation framework. Dependencies point downward only:

```
View (SwiftUI struct)
  └─> ViewModel (@Observable @MainActor final class)
        └─> APIClient.shared  (extension per domain)
              └─> Model (struct, Codable, Hashable)
```

- **There is no service/repository protocol layer and no dependency injection.** All five
  ViewModels call `APIClient.shared` directly. This is the established convention — match it.
  The tradeoff is understood and accepted: ViewModels cannot currently be unit-tested without
  hitting the network. Since there is no test target, nothing is blocked by it today.
  Introducing a protocol + DI layer for a single new feature would make the codebase *less*
  consistent, not more, so don't do it as a side effect of other work. If the team wants that
  layer, it is its own task covering all five ViewModels at once.
- Views hold no business logic and make no network calls.
- ViewModels don't import SwiftUI — they expose data and let Views decide presentation.
- Models are structs conforming to `Identifiable, Codable, Hashable`.
- No third-party dependencies.

## Layout

```
App/          ViadrounikiApp.swift, ContentView.swift (TabView), AppViewModel.swift
Models/       Trip, Point, Vehicle, AppUser, APIResponse, PhotoResource
Network/      APIClient.swift + APIClient+<Domain>.swift extensions, APIError.swift
ViewModels/   <Domain>ListViewModel.swift, <Domain>DetailViewModel.swift
Views/        <Domain>s/ per feature, plus Components/ for shared views
Utilities/    AuthTokenStore, KeychainStore
```

## Shared types — reuse, never redeclare

- `PaginatedResponse<T>`, `PaginationMeta`, `SingleResponse<T>` — all in
  **`Models/APIResponse.swift`**.
- `SortOrder` — in `Network/APIClient+Trips.swift`.
- `PhotoResource` (protocol: `url`, `urlMobile`, `isMain`) — in `Models/PhotoResource.swift`,
  since it's a data contract that model types conform to (`TripPhoto`, `PointPhoto`,
  `VehiclePhoto`), not a view. Its size-class URL selection (`url(for:)`) lives separately in
  `Views/Components/PhotoResource+SizeClass.swift`, since that helper needs SwiftUI's
  `UserInterfaceSizeClass` and the protocol itself must stay SwiftUI-free. The generic
  `PhotoHeroView<Photo: PhotoResource>` is in `Views/Components/`. New photo models should
  conform to `PhotoResource` too rather than hand-rolling size-class URL selection.

## Naming: model and endpoint domains diverge

The API's resource names don't match the app's domain names. Don't assume one placeholder
works across all layers:

| Feature | Model / ViewModel / Views | Network extension | API path |
|---|---|---|---|
| Trips | `Trip`, `TripListViewModel`, `Views/Trips/` | `APIClient+Trips.swift` | `trips` |
| Points | `Point`, `PointListViewModel`, `Views/Points/` | `APIClient+Attractions.swift` | `attractions` |
| Vehicles | `Vehicle`, `VehicleListViewModel`, `Views/Vehicles/` | `APIClient+Cars.swift` | `cars` |

View file naming is also not uniform: `TripListView` and `VehicleListView`, but `PointsView`.

## API conventions

- Every call goes through an `extension APIClient` — never raw `URLSession`.
- `APIClient.get`/`post` handle auth headers centrally; `perform(_:)` maps status codes and
  decode failures to `APIError`. New endpoint functions build a URL and return
  `try await get(url:)` — no error handling of their own.
- Endpoints returning localized text take `locale: String = "ru"` and forward it as a query
  param.
- `get(url:requiresAuth:)` defaults to `false`; `post` always attaches the token when one is
  present, with no opt-out.
- There are **no POST endpoints in the app yet** — login is a UI stub. `APIClient.post` exists
  and works, but a first real POST has no precedent to pattern-match, so confirm body shape
  and auth expectations explicitly.
</content>
</invoke>
