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
  what localizes every `LocalizedStringKey` — `Text`, `Button`, `Picker`, `ContentUnavailableView`,
  `.searchable(prompt:)` — with no per-call-site work. **`.navigationTitle` and `.tabItem`'s
  `Label` are the exception** — see below.
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
    - **`ProfileView` is the one deliberate exception: it keys on `isLoggedIn`, not `\.locale`.**
      Its `auth/me` request takes no `locale` param and returns no server-localized text — name,
      email and handles are user data — so keying on the language would refetch identical bytes
      on every switch. Auth state is the only input that request has. This looks like the
      missing-key bug the review checklist flags 🟡, so the comment at the call site has to say
      why it isn't; don't "fix" it.
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
  - **`.navigationTitle` and `.tabItem`'s `Label` do not reliably re-resolve a
    `LocalizedStringKey` on an environment-only `\.locale` change, for whichever screen or
    tab is currently on screen at the moment the language changes.** The key itself compares
    equal, so SwiftUI has nothing to diff and the UIKit-bridged bar/tab item keeps showing
    the previous language. This was first found on a *pushed* destination (`SettingsView`),
    but is not limited to it — it also hits `ProfileView`'s own root title and its `.tabItem`
    while `ProfileView` is the active tab. **Confirmed by A/B test, not inferred:** reverting
    `ProfileView` to a plain `.navigationTitle("Profile")` and rebuilding reproduces a Russian
    «Профиль» sitting above Belarusian list content and Belarusian tab items; restoring
    `localized(_:)` removes it, in both switch directions. Worth knowing, because the rule
    looks like superstition otherwise and invites someone to "simplify" it away. Plain
    `Text`/`Label` content in a screen's body is unaffected and should keep using
    `LocalizedStringKey` literals as normal.
    - **Fix:** call `AppLanguage.localized(_:)` (in `Models/AppLanguage.swift`) at every
      `.navigationTitle` and `.tabItem` `Label` — e.g. `appViewModel.language.localized("Settings")`.
      It pre-resolves to a `String` off `AppViewModel.language`, a real `@Observable`
      dependency, so the value handed to the modifier genuinely differs between languages
      and `body` is forced to push the update through. See `SettingsView`, `ProfileView`,
      `ContentView`.
    - Do **not** fix it with `.id()` on a pushed destination — that changes its identity,
      which `NavigationStack` reads as the destination disappearing, popping back to the
      previous screen.
    - **Every `.navigationTitle` and `.tabItem` `Label` in the app now goes through the
      helper**, and a new one should too. `TripListView`, `PointsView`, `VehicleListView`, and
      `PointsFilterSheet` were converted defensively rather than in response to a visible
      break: the only language picker lives in `SettingsView` under the Profile tab, so those
      four are always *backgrounded* when the language changes and backgrounded screens rebuild
      correctly. That makes their conversion unverifiable today — it is non-regression, not a
      demonstrated fix — but the mechanism is generic, not specific to `Profile`, and these are
      the screens most likely to gain a language entry point later.
    - Detail-screen titles that interpolate API text (`TripDetailView`, `PointDetailView`,
      `VehicleDetailView`) need nothing: the server already localized that text, and it arrives
      as a `String`, so there is no `LocalizedStringKey` to go stale.
  - A literal only localizes where the parameter is a `LocalizedStringKey`. A `String` variable
    or a ternary of two literals binds to the `StringProtocol` overload instead — pass `Text`
    (as `PointsFilterSheet.row(title:)` and `PointsView` do). Conversely, API-supplied text is
    already localized by the server and must *not* be looked up.
- No third-party dependencies.

## Comments

**Use `///` only — never bare `//`.** This applies everywhere, not just above
declarations: a `///` explaining one line inside a function body is correct, a
`//` doing the same is not. The exceptions are Xcode's special tags —
`// MARK: -`, `// TODO:`, `// FIXME:` — because the jump bar and the tag
scanner only recognize the double-slash form; tripling any of them silently
stops it from being picked up as navigation or as a flagged to-do.

Default to writing no comment at all. Add one only when the WHY is genuinely
non-obvious — a hidden backend behavior, a race avoided on purpose, a
deliberate deviation from the pattern used elsewhere — never to restate what
the code already says. A comment justified by "the reviewer might otherwise
flag this as a bug" (see the localization and concurrency sections above) is
exactly the kind worth keeping.

## Layout

```
App/          ViadrounikiApp.swift, ContentView.swift (TabView), AppViewModel.swift
Assets.xcassets/  AppIcon.appiconset (generated — see below), AccentColor, brand marks
Localizable.xcstrings   String Catalog (source language en; ru + be translations)
Models/       Trip, Point, Vehicle, AppUser, APIResponse, PhotoResource,
              AttractionType, PointFilterKey, AppLanguage
Network/      APIClient.swift + APIClient+<Domain>.swift extensions, APIError.swift
ViewModels/   <Domain>ListViewModel.swift, <Domain>DetailViewModel.swift
Views/        <Domain>s/ per feature, plus Components/ for shared views
Utilities/    AuthTokenStore, KeychainStore
```

`IconSource/` sits at the **repo root** — a sibling of the synchronized `viadrouniki_ios_app/`
folder, not inside it — so the icon's source art and generator are versioned without ever
being swept into the app bundle.

## App icon — generated, do not hand-edit

The three PNGs in `viadrouniki_ios_app/Assets.xcassets/AppIcon.appiconset/`
(`AppIcon-light.png`, `AppIcon-dark.png`, `AppIcon-tinted.png`) are **build output, not
authored artwork.** They are produced from `IconSource/viadrouniki_icon.svg` by
`IconSource/make-app-icon.py` (needs `pip3 install pillow`):

```bash
python3 IconSource/make-app-icon.py
```

Retouching a PNG in an image editor is silently undone the next time anyone runs that script
— no conflict, no warning. Change the SVG, or the script's constants, and regenerate instead.
The script strips the source SVG's own rounded rect (iOS applies its own, larger squircle
mask) and scales the glyph to 75% about the canvas centre; at 100% it spans 82% of the canvas
height and reads as cramped inside the mask.

**Why three files and not one.** Icon appearance on iOS 26 is a *Home Screen* setting —
long-press → Edit → Customise → Default / Dark / Clear / Tinted — **not** a consequence of the
system light/dark theme; only the "Auto" option follows the theme. iOS derives a dark variant
whether or not one is supplied, and for this artwork its guess darkens the background while
leaving the glyph dark, so the «В» nearly vanishes. The explicit `AppIcon-dark.png` exists for
that reason, not to support the theme switch. `AppIcon-tinted.png` is greyscale on black
because the system maps its luminance into the user's chosen tint.

**Icon Composer (`.icon`) was tried and deliberately abandoned** — don't reach for it again
without new information. A working `AppIcon.icon` package builds and renders correctly in
light, but its per-appearance override is undocumented and could not be made to take: probing
with an unmistakable red dark background, in both plausible JSON shapes, never produced red,
so the dark tile was always Apple's auto-derivation. There is no CLI to verify against either
(`--export-preview` just launches the GUI). The format's value is per-layer Liquid Glass on
layered art; this icon is a single flat glyph, so the appiconset costs nothing — iOS still
applies its own glass treatment to the flat image.

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
- **Response envelopes are not uniform — check, don't assume.** Four shapes are in use:
  paginated lists return `{"data": [...], "meta": {...}}` (`PaginatedResponse<T>`); single
  resources and *some* collections return `{"data": ...}` (`SingleResponse<T>`, including
  `SingleResponse<[AttractionType]>` for `attraction-types`); `attractions/map` returns a
  **bare top-level array** with no envelope at all; and `auth/me` returns **`{"user": ...}`**,
  decoded by a `private struct CurrentUserResponse` local to `APIClient+Auth.swift` — one
  endpoint has that shape, so it never joined the shared envelopes in `Models/APIResponse.swift`.
  Picking the wrong one fails at runtime as an `APIError.decodingError`, not at compile time.
  The public endpoints are read-only over GET, so confirm the shape before writing the decode type:
  ```bash
  curl -s 'https://api.viadrouniki.by/v1/<path>?locale=ru' | head -c 400
  ```
  The authed ones (`auth/me`, `user/cars`) can't be confirmed that way — see the `Accept` note below.
- Timestamps are ISO8601 **with fractional seconds** (`2026-01-30T18:55:47.000000Z`). The
  shared decoder in `APIClient` requires them; a field typed `Date` that arrives in any other
  format fails the whole response decode, and making the property optional does *not* rescue
  it — `decodeIfPresent` still runs the date strategy and rethrows.
  - **`AppUser.emailVerifiedAt` is therefore typed `String?`, not `Date?`, on purpose.** It is
    `null` in every payload seen, so its non-null format is unverified — and a wrong guess would
    fail the whole profile decode *only for users who have verified their email*, i.e. invisibly
    in testing. Nothing needs the value, only its nullity (`isEmailVerified`). Don't "improve" it
    to a `Date` without a verified sample. `AppUser` has no `Date` fields at all as a result.
- `get(url:requiresAuth:)` defaults to `false`; `post` always attaches the token when one is
  present, with no opt-out.
- **`perform(_:)` sets `Accept: application/json` on every request, and that header is
  load-bearing — do not remove it as noise.** Laravel emits a JSON 401 only when the request asks
  for JSON; without it, an unauthenticated call to a protected route comes back as **500 with an
  HTML body**, which `perform` maps to `.serverError(500)`, leaving `APIError.unauthorized`
  unreachable and any `catch APIError.unauthorized` dead code. Verified by curl on `auth/me` and
  `user/cars`, in both directions. It is safe on the public endpoints: success responses are
  byte-identical (md5-equal) with and without it on all six shapes the app fetches.
- **Two endpoints require auth: `auth/me` and `user/cars`** (`fetchCurrentUser`, `fetchMyCars`).
  Neither takes a `locale` param — they return user data, not translated content. `fetchMyCars`
  asks for `per_page=100` and keeps no pagination state: the API caps `per_page` at 100 and a
  user's `car_limit` is 25, so the whole list is one page.
  - **`fetchMyCars` has no call site.** `ProfileView`'s "My cars" row is a placeholder with an
    empty action — there's no dedicated cars screen yet — so `ProfileViewModel` only calls
    `fetchCurrentUser`. `fetchMyCars` is kept, dormant, in `APIClient+Cars.swift` for that screen
    when it's built, the same way `fetchCurrentUser` sat unused before this feature wired it up.
  - **`user/cars`'s element type is a presumption, not a verified fact.** It decodes as
    `PaginatedResponse<Vehicle>` because it is the same backend's cars resource, but `data` was
    `[]` in every payload ever seen, and an empty array decodes cleanly against *any* element
    type. `Vehicle` is a wide, strict target (non-optional `brand`, `model`, `year`, `user`,
    `photosCount`, `tripsCount`, `isActive`, `canDelete`, and two non-optional fractional-seconds
    `Date`s), so a lighter "my cars" serializer would break it. The first account that actually
    owns a car is the real test.
- There are **no POST endpoints in the app yet** — login is a UI stub. `APIClient.post` exists
  and works, but a first real POST has no precedent to pattern-match, so confirm body shape
  and auth expectations explicitly. Two features are parked on this: `ProfileView`'s **`Add car`
  row**, which shows an "isn't available yet" alert because the create-car path, body shape and
  photo-upload flow are all unspecified; and `ProfileAccountView`'s **Telegram settings rows**,
  which are read-only `LabeledContent` for the same reason. Neither is an oversight — don't
  "finish" either by guessing a request shape, and don't turn the settings rows into `Toggle`s
  (disabled or otherwise) while they can't be written back.
</content>
</invoke>
