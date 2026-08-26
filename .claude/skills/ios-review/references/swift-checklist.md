# Swift/SwiftUI Review Checklist — viadrouniki_ios_app

Project constants live in `CLAUDE.md` (repo root). Short version for this checklist:
iOS 26.5 target, **Swift 5 language mode with `minimal` strict concurrency**,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, MVVM + `@Observable`, SwiftUI only,
no service/DI layer, no test target, localized in Russian + Belarusian via
`Localizable.xcstrings` (source language English, and no English UI ships).

## Contents
1. Architecture & layering
2. Concurrency
3. SwiftUI correctness
4. Swift language & memory
5. Generated-code hazards
6. Testing (no test target — read before flagging)
7. Naming & style
8. Localization (ru + be — compiler-invisible, read before flagging or approving)

---

## §1 Architecture & layering

Layers, top to bottom. Dependencies point downward only.

```
View (SwiftUI struct)
  └─> ViewModel (@Observable @MainActor final class)
        └─> APIClient.shared  (extension APIClient, one file per domain)
              └─> Model (struct, Codable, Hashable)
```

Check:
- [ ] Views contain NO business logic, NO networking, NO persistence calls. A View may only read ViewModel state and call ViewModel methods. (Flutter mapping: same rule as keeping logic out of `build()`.)
- [ ] ViewModels are `@Observable @MainActor final class`. Never `ObservableObject`, never `@Published` — those are the legacy pattern and are a 🔴 blocker in this project.
- [ ] ViewModels do not import SwiftUI. If a ViewModel needs SwiftUI types (Color, Image), the design is wrong — expose data, let the View decide presentation.
- [ ] ViewModels reach the network through `APIClient.shared` directly. **This is correct here** — there is no service protocol layer and no DI, by decision (see `CLAUDE.md`). Do not flag it, and do not propose introducing a protocol/DI layer as part of an unrelated review.
- [ ] Networking goes through an `extension APIClient`, never raw `URLSession` at the call site. New endpoints add nothing but a URL and `try await get(url:)` — error handling is centralized in `APIClient.perform(_:)`, so per-endpoint `do/catch` is a 🟡 finding.
- [ ] Shared types are reused, not redeclared: `PaginatedResponse`/`PaginationMeta`/`SingleResponse` (`Models/APIResponse.swift`), `SortOrder` (`APIClient+Trips.swift`), `PhotoResource`/`PhotoHeroView` (`Views/Components/`), `AttractionType` (`Models/AttractionType.swift`). Redeclaring any of these is a 🔴. The full list is in `CLAUDE.md`; read it rather than trusting this line to stay current.
- [ ] **Nothing under `Models/` imports SwiftUI.** A model that needs a `Color`, SF Symbol, or size class gets a `<Type>+<Purpose>.swift` extension under `Views/Components/` — the split `PhotoResource`/`PhotoResource+SizeClass` and `AttractionType`/`AttractionType+Presentation` both follow. A SwiftUI import under `Models/` is a 🟡 misplacement, even when the code inside it is correct.
- [ ] A model shared by more than one endpoint lives in its own file, not inside the first model file that happened to need it — and adding a field to it widens the decode surface of *every* response that embeds it. `AttractionType` is embedded in `TripAttraction`, so a new field there can break the trips screens.
- [ ] Models are structs. A class model needs a written justification (identity semantics, reference sharing).
- [ ] New photo models conform to `PhotoResource` instead of hand-rolling size-class URL selection.
- [ ] Domain vocabulary the app invents (as opposed to decodes) is a named type, not an overloaded `Optional`. `PointFilterKey.unknown` beats `nil` as a dictionary key meaning "no type, or a type we don't recognise" — `Set<Int?>` typechecks but hides the case from the reader.
- [ ] No new third-party dependencies introduced without explicit approval in the task description.

## §2 Concurrency

**Read this section carefully — the compiler is not helping you here.** The project is in
Swift 5 language mode and `SWIFT_STRICT_CONCURRENCY` is never set, so it defaults to
`minimal`: data-race safety is essentially unchecked. Everything below must be verified by
reading. A clean build says nothing about any of it.

`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` also inverts the usual question. Unannotated
types are *already* main-actor-isolated, so "is this on the main actor?" is almost always
yes. Ask instead: **should this be off the main actor, and has anyone arranged for that?**

- [ ] Work that should not block the UI is actually off the main actor. Note that `APIClient`
      carries no isolation annotation, so it is implicitly `@MainActor` — request setup and
      JSON decoding run on the main actor. `await session.data(for:)` suspends rather than
      blocks, so this is not a hang, but large decodes do cost main-thread time. Flag as 🟡
      only with a concrete reason (a big payload, a measured hitch), not on principle.
- [ ] Types crossing isolation boundaries are `Sendable`. Prefer structs. `@unchecked Sendable` is a 🔴 blocker unless accompanied by a comment proving thread safety (e.g., internal lock). The compiler will *not* flag missing conformances in this mode — check by hand.
- [ ] Redundant-but-harmless `@MainActor` on ViewModels is fine and conventional here. Don't file findings asking for its removal.
- [ ] No `DispatchQueue`, no `DispatchGroup`, no completion-handler APIs where an async equivalent exists. Legacy callback APIs must be bridged with `withCheckedThrowingContinuation` — and check the continuation resumes exactly once on every path.
- [ ] `Task { }` inside ViewModels: check for unstructured task leaks. Long-running tasks stored in a property must be cancelled in `deinit` or when superseded (e.g., a new search cancels the previous one).
- [ ] `Task.detached` is almost always wrong — flag it and ask why it isn't a plain `Task` or an actor method.
- [ ] No blocking calls (`Thread.sleep`, synchronous I/O, `semaphore.wait`) inside async contexts.
- [ ] Shared mutable state outside the MainActor lives in an actor, not behind locks, unless there's a measured performance reason.
- [ ] Check cancellation: loops and long awaits in cancellable tasks should call `Task.checkCancellation()` or check `Task.isCancelled`.

Flutter mapping (one-liner for review comments): Dart gives you one isolate and no data races
for free. Swift *can* enforce the same guarantee at compile time, but this project hasn't
turned that on yet — so treat concurrency here like Dart with `async` that can genuinely run
on multiple threads: the safety has to come from you, not the toolchain.

## §3 SwiftUI correctness

Property wrappers — the #1 source of AI-generated bugs:
- [ ] `@State` for view-local value state AND for owning an `@Observable` object created by the view (`@State private var viewModel = FeedViewModel(...)`).
- [ ] Plain `let`/`var` (no wrapper) for `@Observable` objects passed in from a parent. `@ObservedObject`/`@StateObject` appearing anywhere = legacy pattern = 🔴.
- [ ] `@Bindable` when the view needs bindings into an `@Observable` object passed in.
- [ ] `@Binding` only for value types owned by a parent.
- [ ] `@Environment` for app-wide dependencies; check the value is actually installed with `.environment()` at an ancestor, or the app crashes at runtime.

View body rules:
- [ ] `body` is pure: no side effects, no object creation with side effects, no logging, no `Task { }` launches. Side effects belong in `.task`, `.onChange`, or ViewModel methods.
- [ ] Async work on appearance uses `.task { }` (auto-cancelled on disappear), not `.onAppear { Task { } }` (leaks the task). 🟡 finding.
- [ ] `ForEach` identity: stable `id` (model conforms to `Identifiable` with a real id, not `\.self` on non-unique values, never array indices for mutable lists).
- [ ] No `AnyView` unless genuinely required by heterogeneous storage; prefer `@ViewBuilder`.
- [ ] View bodies over ~50 lines: suggest extracting subviews or computed properties. (Flutter mapping: same instinct as splitting a giant `build()` into widgets.)
- [ ] Navigation uses `NavigationStack` with typed paths, not deprecated `NavigationView`.
- [ ] Deployment target is iOS 26.5, so current APIs are available unconditionally and availability checks are almost never needed — flag `if #available` guards for anything already covered by the target. Note that some existing code predates this and still uses older equivalents (`ContentView`'s `.tabItem`/`.tag` rather than `Tab`); modernizing it is a deliberate task, not something to demand in an unrelated review.
- [ ] **Localization** — see §8. Short version for View review: an English literal inline in a
      View is correct (English is the catalog's source language, so the literal *is* the key),
      but a literal with no `Localizable.xcstrings` entry, a fetching screen whose `.task` isn't
      keyed on `@Environment(\.locale)`, and a `String`-typed argument that silently misses the
      `LocalizedStringKey` overload are all real findings.

## §4 Swift language & memory

- [ ] No force unwraps (`!`) or force tries (`try!`) in production code. Allowed in tests and `#Preview` blocks. `IUO` properties (`var x: T!`) are a 🔴 outside of rare framework-imposed cases.
- [ ] **Trapping initializers applied to server data.** `!` is not the only way to crash on a
      payload. `Dictionary(uniqueKeysWithValues:)` traps on a duplicate key, `Array`
      subscripting traps out of range, and `precondition`/`fatalError` in a decode path trap by
      design — none of them throw, so `APIError` handling and `try?` do not catch them. When
      the input comes from the API, prefer the total form:
      ```swift
      // traps if the API ever repeats an id
      Dictionary(uniqueKeysWithValues: types.map { ($0.id, $0) })
      // resolves instead
      Dictionary(types.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
      ```
      (Flutter mapping: Dart would just overwrite the duplicate key and move on — Swift's
      "unique" initializer means *you promise* they're unique, and it kills the app if you're
      wrong.)
- [ ] No `try?` that silently swallows errors on user-facing flows — errors surface to the ViewModel and become presentable state (alert, inline message, retry).
- [ ] Closures stored by a class capture `self` weakly (`[weak self]`) unless the lifetime relationship is provably safe — document it if so. Delegate properties are `weak var`. (Flutter mapping: Dart's GC collects cycles; ARC does not — this is new for you and generated code gets it wrong constantly.)
- [ ] Escaping closures in async pipelines: prefer async functions over closure callbacks entirely.
- [ ] `guard let` early exits over pyramid `if let` nesting.
- [ ] Value semantics respected: don't "fix" struct mutation problems by switching to a class; use `mutating` or restructure.
- [ ] Access control: default to `private`/`private(set)`; nothing `public` in an app target without reason.

## §5 Generated-code hazards

These checks exist specifically because code in this project is AI-generated.

- [ ] **Hallucinated APIs.** Verify every non-obvious API against real SDK surface: method names, parameter labels, availability. Generated code invents plausible-looking methods (`.navigationBarLargeTitle(true)`, `URLSession.shared.fetch(...)`). If the build passes this is covered; if reviewing statically, verify anything you don't personally recognize.
- [ ] **Deprecated patterns presented as current.** Common ones: `NavigationView`, `ObservableObject`/`@Published`/`@StateObject`, `.foregroundColor` vs `.foregroundStyle`, `onChange(of:) { newValue in }` single-parameter form, `Task.init` for fire-and-forget UI updates instead of `.task`.
- [ ] **Duplicated logic.** Search the codebase for existing extensions, formatters, network helpers before accepting new ones. Generated code re-creates what it can't see.
- [ ] **One rule encoded twice, two different ways.** The subtler form of duplication: the same
      business concept expressed with different criteria in different layers — e.g. a ViewModel
      hiding amenities by `slug` in `["cafe", "azs"]` while a View groups them by
      `sort_order >= 100`. Both are "which types are amenities?", they agree today, and they
      will drift the moment a third amenity is added. Verify against live data whether two such
      rules currently select the same rows (step 4 of the workflow), then collapse them into
      one named property on the model — `isAmenity` — that both layers read.
- [ ] **Speculative generality.** Protocols with one conformer created "for flexibility", generic parameters never used with a second type, configuration options nothing configures. Delete unless the task asked for it.
- [ ] **Orphaned code.** Unused properties, dead functions, commented-out blocks, `// TODO` left by the generator.
- [ ] **Fabricated resources.** References to asset names, localization keys, or file resources that don't exist in the bundle — these fail silently or at runtime, not at compile time.
- [ ] **Guessed response envelopes.** `PaginatedResponse<T>` vs `SingleResponse<T>` vs a bare
      top-level array is not inferable from the endpoint's name, and picking wrong compiles
      fine and fails at runtime as `APIError.decodingError`. `curl` the endpoint (workflow
      step 4) rather than pattern-matching a neighbouring function. Same for `Date` fields —
      see the fractional-seconds note in `CLAUDE.md`; optionality does not rescue a bad format.
- [ ] **Plausible-but-wrong logic.** Off-by-one in pagination, inverted booleans in guard conditions, wrong comparison in sorting. Read the logic as if it were written by a confident intern.
- [ ] **Non-deterministic ordering.** `Dictionary`/`Set` iteration order is unspecified, and
      Swift's `sorted(by:)` is **not stable**, so sorting an unordered collection on a key with
      ties gives an arbitrary order for the tied elements — rows that visibly shuffle between
      presentations. Check whether the sort key really is unique in the live data before
      accepting a single-key sort; if it isn't, require a tiebreak on `id`:
      ```swift
      .sorted { ($0.sortOrder ?? 0, $0.id) < ($1.sortOrder ?? 0, $1.id) }
      ```
- [ ] **Unreachable defaults.** When initial state is computed inside a one-shot guarded load
      (`guard mapPoints.isEmpty else { return }`), any UI control that overwrites that state
      makes the default unrecoverable for the rest of the session. Trace every reset/clear
      control back to whether the user can actually return to the starting state, and check
      that a "Reset" labelled control restores defaults rather than clearing to empty — an
      empty selection that renders a blank screen with no explanation is a bug, not a filter.

## §6 Testing

**There is no test target in this project** — one application target and nothing else. Do not
raise missing tests as a finding, do not ask for test coverage on new ViewModels, and do not
create test files; they would not compile into anything.

This follows from the no-DI decision in §1: ViewModels call `APIClient.shared` directly, so
they can't be constructed against a fake anyway. The two decisions are consistent, and both
are recorded in `CLAUDE.md`.

If a change is complex enough that its correctness genuinely can't be established by reading,
say so in the verdict and suggest adding a test target as its own task. Once one exists, this
section becomes: Swift Testing (`@Test`, `#expect`) for new tests, assert behavior over
implementation details, no `sleep`-based synchronization.

## §7 Naming & style

- [ ] Swift API Design Guidelines: methods read as phrases (`insert(_:at:)`), booleans read as assertions (`isLoading`, `hasError`).
- [ ] ViewModels named `<Feature>ListViewModel` / `<Feature>DetailViewModel`; network files `APIClient+<APIDomain>.swift`; fetch methods `fetch<Domain>s` / `fetch<Domain>(id:)` / `fetch<Domain><Noun>`.
- [ ] Model and API domain names diverge in this project (`Point` ↔ `attractions`, `Vehicle` ↔ `cars`) — see the table in `CLAUDE.md`. Matching the existing name for the layer you're in is correct; "fixing" one layer to match another is a rename task, not a review finding.
- [ ] One primary type per file; file named after the type.
- [ ] No Flutter-isms leaking in: no `build()` helper methods returning views (use computed `var` or subviews), no `Widget`-style deeply nested initializer trees when modifiers do the job.
- [ ] `// MARK: -` sections in files over ~100 lines.

## §8 Localization

The app ships **Russian and Belarusian** (`Localizable.xcstrings` at the root of the source
folder) and **no English UI**. English is the catalog's *source language*, so UI strings stay
written as English literals inline in Views — the literal is the key.

Read this section before approving anything that adds user-facing text or a fetching screen.
None of the failures below are caught by the compiler or visible in a green build: they show
up as English text on a Russian screen, or as a screen stuck in the language the user just
switched away from.

**Catalog coverage**
- [ ] Every new user-facing literal has an `Localizable.xcstrings` entry with **both** `ru`
      and `be`. A missing entry falls back to the English key and renders English to a user
      who will never see an English UI. Verify rather than eyeball — the catalog is JSON:
      ```bash
      python3 -c "
      import json; d = json.load(open('viadrouniki_ios_app/Localizable.xcstrings'))
      for k, v in d['strings'].items():
          if v.get('shouldTranslate') is False: continue
          missing = {'ru', 'be'} - set(v.get('localizations', {}))
          if missing: print(sorted(missing), repr(k))
      "
      ```
      Entries marked `shouldTranslate: false` are pure format strings (`\"%@ · %@\"`) and are
      *supposed* to have no translations — skipping them is why the filter is there, not an
      oversight to fix.
- [ ] Vocabulary matches the existing catalog rather than being freshly invented. Cars are
      «машина»/«машына» (not «аўтамабіль»), trips are «маршрут» in both languages. Gender
      agreement travels with the noun: «ни одна машина», not «ни один автомобиль».
- [ ] No second catalog key for something an existing key already covers. The tab item, the
      Cars list title, and the trip-detail section heading deliberately share one `Cars` key
      so the wording can't drift; adding a parallel key reintroduces the drift. See `CLAUDE.md`.

**Language changes must reach the network layer**
- [ ] A new screen that *fetches* keys its `.task` on `@Environment(\.locale)`. The `locale`
      query param is baked into responses the ViewModel already holds, so `.environment(\.locale,)`
      alone cannot fix them — without the key the screen keeps serving the previous language
      until something unrelated reloads it. 🟡.
- [ ] Where a `.task` already had an id, the language joins it in the **same** `Equatable`
      struct (`PointsRequest`, `VehiclesRequest`) — a second `.task` is a 🟡: both fire on
      appear and race, with only the `isLoading` guard keeping it to one request.
- [ ] Row-level pagination `.task`s (`fetchMoreIfNeeded`) stay **unkeyed**. Don't ask for a key
      there; the reload replaces the whole list anyway.
- [ ] `.id(appViewModel.language)` at the root is a 🔴 regression, not a shortcut — it refetches
      by destroying the tree, taking every `NavigationStack` path and scroll position with it.
      That was the original approach and it was deliberately replaced.
- [ ] A guarded load that stamps what it loaded (`PointListViewModel.loadedMapLocale`) guards on
      the **locale**, not on `collection.isEmpty`. The `isEmpty` version is the obvious one and
      it silently blocks the language refetch.

**Outside SwiftUI, the environment does not reach you**
- [ ] `String(localized:)` in a Model, ViewModel, or Network file passes
      `bundle: AppLanguage.current.bundle`. This is the single easiest thing to get wrong here:
      `locale:` only formats interpolated values — the *translation lookup* goes through the
      device's preferred localization and ignores it entirely. With the device in English,
      `String(localized: "Hello", locale: Locale(identifier: "ru"))` returns the **Belarusian**
      string. Keep `locale:` too, for interpolated numbers and dates. See `APIError`,
      `VehicleSchedule.label`.
- [ ] `Locale.current` is the *device* language and is essentially always wrong in this project
      — iOS has no Belarusian display language at all. Expect `AppLanguage.current.locale`, or
      `@Environment(\.locale)` inside a View.
- [ ] `Date` format styles pass `.locale(_:)` (see `TripCardView`). For these, unlike
      `String(localized:)`, `locale` alone is sufficient.

**Overload resolution silently opts out**
- [ ] A literal only localizes where the parameter is a `LocalizedStringKey`. A `String`
      variable, or a ternary of two literals, binds to the `StringProtocol` overload instead
      and renders verbatim. Fix by passing `Text` (see `PointsFilterSheet.row(title:)`,
      `PointsView`). This compiles cleanly either way, so it has to be read for.
- [ ] Conversely, API-supplied text is **already** localized by the server and must not be run
      through a lookup — doing so produces a miss and echoes the string back by luck, not design.

**Known backend gap, not an app bug**
- [ ] `attraction-types` returns Russian names even for `locale=be`. Don't file it against the
      diff under review; it's recorded in `CLAUDE.md`.
