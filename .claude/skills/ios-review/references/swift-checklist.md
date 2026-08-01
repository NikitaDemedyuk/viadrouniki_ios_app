# Swift/SwiftUI Review Checklist — viadrouniki_ios_app

Project constants live in `CLAUDE.md` (repo root). Short version for this checklist:
iOS 26.5 target, **Swift 5 language mode with `minimal` strict concurrency**,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, MVVM + `@Observable`, SwiftUI only,
no service/DI layer, no test target.

## Contents
1. Architecture & layering
2. Concurrency
3. SwiftUI correctness
4. Swift language & memory
5. Generated-code hazards
6. Testing (no test target — read before flagging)
7. Naming & style

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
- [ ] Shared types are reused, not redeclared: `PaginatedResponse`/`PaginationMeta`/`SingleResponse` (`Models/APIResponse.swift`), `SortOrder` (`APIClient+Trips.swift`), `PhotoResource`/`PhotoHeroView` (`Views/Components/`). Redeclaring any of these is a 🔴.
- [ ] Models are structs. A class model needs a written justification (identity semantics, reference sharing).
- [ ] New photo models conform to `PhotoResource` instead of hand-rolling size-class URL selection.
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
- [ ] Text shown to users is localizable (`String(localized:)` or string literals in `Text` which auto-localize) — flag hardcoded user-facing strings built with interpolation that bypasses localization.

## §4 Swift language & memory

- [ ] No force unwraps (`!`) or force tries (`try!`) in production code. Allowed in tests and `#Preview` blocks. `IUO` properties (`var x: T!`) are a 🔴 outside of rare framework-imposed cases.
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
- [ ] **Speculative generality.** Protocols with one conformer created "for flexibility", generic parameters never used with a second type, configuration options nothing configures. Delete unless the task asked for it.
- [ ] **Orphaned code.** Unused properties, dead functions, commented-out blocks, `// TODO` left by the generator.
- [ ] **Fabricated resources.** References to asset names, localization keys, or file resources that don't exist in the bundle — these fail silently or at runtime, not at compile time.
- [ ] **Plausible-but-wrong logic.** Off-by-one in pagination, inverted booleans in guard conditions, wrong comparison in sorting. Read the logic as if it were written by a confident intern.

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
