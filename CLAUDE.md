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

- **There is no service/repository protocol layer and no dependency injection.** All six
  ViewModels in `ViewModels/` call `APIClient.shared` directly (`AppViewModel` in `App/` does
  no networking). This is the established convention — match it.
  The tradeoff is understood and accepted: ViewModels cannot currently be unit-tested without
  hitting the network. Since there is no test target, nothing is blocked by it today.
  Introducing a protocol + DI layer for a single new feature would make the codebase *less*
  consistent, not more, so don't do it as a side effect of other work. If the team wants that
  layer, it is its own task covering all six ViewModels at once.
- Views hold no business logic and make no network calls.
- ViewModels don't import SwiftUI — they expose data and let Views decide presentation.
- API payload models are structs conforming to `Identifiable, Codable, Hashable`. Not
  everything in `Models/` is a payload model, though — `PointFilterKey` is a plain `Hashable`
  enum with no `Codable` conformance, because it's app-side vocabulary shared by a ViewModel
  and a View rather than anything the API sends.
- **There is no localization catalog** — no `.xcstrings`, no `.lproj`. User-facing text is
  English string literals inline in Views, while the API is asked for `locale: "ru"` content.
  That is the current convention; do not flag hardcoded UI strings as a review finding, and do
  not introduce `String(localized:)` piecemeal. Localizing the app is its own task.
- No third-party dependencies.

## Layout

```
App/          ViadrounikiApp.swift, ContentView.swift (TabView), AppViewModel.swift
Models/       Trip, Point, Vehicle, AppUser, APIResponse, PhotoResource,
              AttractionType, PointFilterKey
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
- `AttractionType` — in `Models/AttractionType.swift`, **not** in `Trip.swift`, even though
  `TripAttraction.type` is one. It backs its own endpoint as well, so it's shared: adding a
  field to it widens the decode surface of the trips responses too. Its SwiftUI presentation
  helpers (`parsedColor`, `sfSymbolName`) live in
  `Views/Components/AttractionType+Presentation.swift`.
- `PointFilterKey` (`.type(Int)` / `.unknown`) — in `Models/PointFilterKey.swift`, with the
  `Collection<AttractionType>` helpers that build selections of it. It exists so the
  "point has no type, or a type the app doesn't know" case is named rather than smuggled
  through an `Optional` key.

**The model/presentation split is a rule, not two coincidences.** Types in `Models/` never
import SwiftUI. When a model needs a `Color`, an SF Symbol, a size class, or any other
SwiftUI-derived value, that goes in a `<Type>+<Purpose>.swift` extension under
`Views/Components/`. Both `PhotoResource` and `AttractionType` follow this; a SwiftUI import
appearing under `Models/` is the signal that something landed in the wrong folder.

## Naming: model and endpoint domains diverge

The API's resource names don't match the app's domain names. Don't assume one placeholder
works across all layers:

| Feature | Model / ViewModel / Views | Network extension | API path |
|---|---|---|---|
| Trips | `Trip`, `TripListViewModel`, `Views/Trips/` | `APIClient+Trips.swift` | `trips` |
| Points | `Point`, `PointListViewModel`, `Views/Points/` | `APIClient+Attractions.swift` | `attractions`, `attraction-types` |
| Vehicles | `Vehicle`, `VehicleListViewModel`, `Views/Vehicles/` | `APIClient+Cars.swift` | `cars` |

View file naming is also not uniform: `TripListView` and `VehicleListView`, but `PointsView`.

## API conventions

- Every call goes through an `extension APIClient` — never raw `URLSession`.
- `APIClient.get`/`post` handle auth headers centrally; `perform(_:)` maps status codes and
  decode failures to `APIError`. New endpoint functions build a URL and return
  `try await get(url:)` — no error handling of their own.
- Endpoints returning localized text take `locale: String = "ru"` and forward it as a query
  param.
- **Response envelopes are not uniform — check, don't assume.** Three shapes are in use:
  paginated lists return `{"data": [...], "meta": {...}}` (`PaginatedResponse<T>`); single
  resources and *some* collections return `{"data": ...}` (`SingleResponse<T>`, including
  `SingleResponse<[AttractionType]>` for `attraction-types`); and `attractions/map` returns a
  **bare top-level array** with no envelope at all. Picking the wrong one fails at runtime as
  an `APIError.decodingError`, not at compile time. The API is public and read-only over GET,
  so confirm the shape before writing the decode type:
  ```bash
  curl -s 'https://api.viadrouniki.by/v1/<path>?locale=ru' | head -c 400
  ```
- Timestamps are ISO8601 **with fractional seconds** (`2026-01-30T18:55:47.000000Z`). The
  shared decoder in `APIClient` requires them; a field typed `Date` that arrives in any other
  format fails the whole response decode, and making the property optional does *not* rescue
  it — `decodeIfPresent` still runs the date strategy and rethrows.
- `get(url:requiresAuth:)` defaults to `false`; `post` always attaches the token when one is
  present, with no opt-out.
- There are **no POST endpoints in the app yet** — login is a UI stub. `APIClient.post` exists
  and works, but a first real POST has no precedent to pattern-match, so confirm body shape
  and auth expectations explicitly.
</content>
</invoke>
