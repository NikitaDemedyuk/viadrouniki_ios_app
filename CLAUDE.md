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
- **The app is localized in Russian and Belarusian** via `Localizable.xcstrings` at the root of
  the source folder. There is deliberately **no English UI** — the API has no English content
  (`locale=en` silently returns Russian). English remains only the catalog's *source language*,
  so UI strings are still written as English literals inline in Views; that's the key, not
  something the user ever sees. New user-facing text needs a catalog entry with `ru` and `be`.
- **The language is app-controlled, not system-controlled.** iOS ships no Belarusian display
  language, so it can't be selected in Settings and the per-app language picker can't offer it
  either. `AppLanguage` (UserDefaults-backed, defaults to Russian) is the source of truth, and
  `ViadrounikiApp` forces it onto the tree with `.environment(\.locale,)`. That one modifier is
  what localizes every `LocalizedStringKey` — `Text`, `Label`, `.navigationTitle`, `Button`,
  `Picker`, `ContentUnavailableView`, `.searchable(prompt:)` — with no per-call-site work.
  - That modifier only covers catalog strings. **API content is a separate problem**: the
    `locale` query param is baked into responses already held by ViewModels, so a language
    change has to refetch. Every screen that loads content keys its `.task` on
    `@Environment(\.locale)` — `TripListView`, `PointsView` (list *and* map), `VehicleListView`,
    and all three detail views. **A new fetching screen must do the same, or it will keep
    showing the previous language until something else happens to reload it.**
    - Where a `.task` already had a key, the language joins it in one `Equatable` struct
      (`PointsRequest`, `VehiclesRequest`) rather than becoming a second `.task` — two tasks
      calling the same fetch both fire on appear and race, with only the `isLoading` guard
      keeping it to one request.
    - Pagination `.task`s (`fetchMoreIfNeeded`) stay unkeyed. They're per-row and the reload
      replaces the whole list anyway.
    - `PointListViewModel.fetchMapPoints()` is the one guarded load, because the map's `.task`
      re-runs whenever the map reappears. It stamps `loadedMapLocale` on success, so a
      list↔map toggle doesn't refetch but a language change does. Guarding on
      `mapPoints.isEmpty` instead — the obvious version — silently blocks the language refetch.
    - Doing this with `.id(appViewModel.language)` at the root also works and is shorter, but
      it refetches by destroying the tree: every `NavigationStack` path and scroll position
      goes with it. It was the original approach; don't reintroduce it.
  - **Anything resolved outside SwiftUI does not see that environment value** and must be
    pointed at the language explicitly. `Locale.current` is the *device* language and is
    essentially always wrong here.
    - For `Date` format styles, `.locale(_:)` is enough (see `TripCardView`).
    - For `String(localized:)`, it is **not**. `locale:` only formats the interpolated
      values; the translation lookup goes through the *device's* preferred localization and
      ignores it. Verified: with `ru.lproj`/`be.lproj` in the bundle and the device set to
      English, `String(localized: "Hello", locale: Locale(identifier: "ru"))` returns the
      Belarusian string. **Pass `bundle: AppLanguage.current.bundle`** — that is what
      actually selects the language (see `APIError`, `VehicleSchedule.label`). Keep passing
      `locale:` too, for interpolated numbers and dates.
  - A literal only localizes where the parameter is a `LocalizedStringKey`. A `String` variable
    or a ternary of two literals binds to the `StringProtocol` overload instead — pass `Text`
    (as `PointsFilterSheet.row(title:)` and `PointsView` do). Conversely, API-supplied text is
    already localized by the server and must *not* be looked up.
- No third-party dependencies.

## Layout

```
App/          ViadrounikiApp.swift, ContentView.swift (TabView), AppViewModel.swift
Localizable.xcstrings   String Catalog (source language en; ru + be translations)
Models/       Trip, Point, Vehicle, AppUser, APIResponse, PhotoResource,
              AttractionType, PointFilterKey, AppLanguage
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
- `AppLanguage` (`.russian` / `.belarusian`) — in `Models/AppLanguage.swift`. The single source
  of truth for the UI language *and* the API `locale` param. It's a static rather than a
  property on `AppViewModel` because `APIClient` reads it, and the dependency direction forbids
  the client reaching back up into a ViewModel. It vends three things, and they are not
  interchangeable: `locale` (SwiftUI's `\.locale`, and formatting), `apiLocale` (the query
  param), and `bundle` (the `.lproj` that `String(localized:bundle:)` needs).
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

The API's resource names don't match the app's domain names, and since localization landed,
neither matches what the user actually reads. **Three independent vocabularies**, so don't
assume one placeholder works across all layers:

| Feature | Model / ViewModel / Views | Network extension | API path | Catalog key | Shown as (ru / be) |
|---|---|---|---|---|---|
| Trips | `Trip`, `TripListViewModel`, `Views/Trips/` | `APIClient+Trips.swift` | `trips` | `Trips` | Маршруты / Маршруты |
| Points | `Point`, `PointListViewModel`, `Views/Points/` | `APIClient+Attractions.swift` | `attractions`, `attraction-types` | `Points` | Точки / Кропкі |
| Vehicles | `Vehicle`, `VehicleListViewModel`, `Views/Vehicles/` | `APIClient+Cars.swift` | `cars` | `Cars` | Машины / Машыны |

The trips row is identical in both languages, and that is correct, not an untranslated
placeholder: «маршрут» is the same word in Russian and Belarusian. The catalog is consistent
about it — `Failed to load trips` and the `%lld trips` plurals all build on «маршрут», not
«паездка» — so changing any one of them means changing all three.

The vehicles row is the one that diverges at every level: the type is `Vehicle`, the endpoint
is `cars`, and the UI says `Cars` → «Машины». **This is deliberate — don't "fix" it by renaming
one layer to match another.** Renaming the types is its own task, and it would have to cover
`Vehicle`, `VehicleListViewModel`, `VehicleDetailViewModel`, `VehicleCardView`,
`VehicleListView`, `VehicleDetailView`, `VehicleSchedule`, `VehiclePhoto`, `VehicleOwner`, and
`Views/Vehicles/` all at once.

There is deliberately **no `Vehicles` catalog key**. The tab item (`ContentView`), the list
screen title (`VehicleListView`), and the trip-detail section heading (`TripDetailView`) all
share the single `Cars` key, so the wording can never drift between them. Adding a second key
for any of those three would reintroduce exactly that drift.

Sharing a key only protects the strings that share it, though — the *other* car-related
strings are separate keys and have to be kept in vocabulary by hand. `Failed to load vehicles`,
`No cars linked to this trip yet`, and `There aren't any trips with this car right now` all say
«машина»/«машына» to match `Cars`; they previously said «автомобиль»/«аўтамабіль». Note the
gender agreement travels with the noun — «ни одна машина», not «ни один автомобиль».

View file naming is also not uniform: `TripListView` and `VehicleListView`, but `PointsView`.

## API conventions

- Every call goes through an `extension APIClient` — never raw `URLSession`.
- `APIClient.get`/`post` handle auth headers centrally; `perform(_:)` maps status codes and
  decode failures to `APIError`. New endpoint functions build a URL and return
  `try await get(url:)` — no error handling of their own.
- Endpoints returning localized text take `locale: String = AppLanguage.current.apiLocale` and
  forward it as a query param, so API content follows the app's language. Default argument
  values are evaluated per call site, which is what keeps this dynamic. Only `ru` and `be` are
  real: `locale=en` is accepted but silently returns Russian.
  - `AppLanguage` is `nonisolated` for exactly this reason — default argument values are
    evaluated in a nonisolated context, and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` would
    otherwise make reading it a concurrency violation.
  - Known backend gap: `attraction-types` returns Russian names even for `locale=be`.
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
