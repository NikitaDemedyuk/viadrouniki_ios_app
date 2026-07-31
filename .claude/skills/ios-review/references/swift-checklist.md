# Swift/SwiftUI Review Checklist — viadrouniki_ios_app

Project constants: iOS 18 minimum, Swift 6 strict concurrency, MVVM + @Observable, SwiftUI only.

## Contents
1. Architecture & layering
2. Swift 6 concurrency
3. SwiftUI correctness
4. Swift language & memory
5. Generated-code hazards
6. Testing & testability
7. Naming & style

---

## §1 Architecture & layering

Layers, top to bottom. Dependencies point downward only.

```
View (SwiftUI struct)
  └─> ViewModel (@MainActor @Observable final class)
        └─> Service / Repository (protocol + concrete impl, injected)
              └─> Model (struct, Sendable, Codable where needed)
```

Check:
- [ ] Views contain NO business logic, NO networking, NO persistence calls. A View may only read ViewModel state and call ViewModel methods. (Flutter mapping: same rule as keeping logic out of `build()`.)
- [ ] ViewModels are `@MainActor @Observable final class`. Never `ObservableObject`, never `@Published` — those are the legacy pattern and are a 🔴 blocker in this project.
- [ ] ViewModels do not import SwiftUI. If a ViewModel needs SwiftUI types (Color, Image), the design is wrong — expose data, let the View decide presentation.
- [ ] Services are defined as protocols; concrete implementations are injected through the initializer. No singletons accessed directly from ViewModels (`URLSession.shared` inside a service impl is fine; `APIClient.shared` reached from a ViewModel is not).
- [ ] Models are structs. A class model needs a written justification (identity semantics, reference sharing).
- [ ] No new third-party dependencies introduced without explicit approval in the task description.

## §2 Swift 6 concurrency

Strict concurrency is on. The compiler catches much, but review for design, not just compilation.

- [ ] Everything that touches UI state is `@MainActor`. ViewModels: whole class, not method-by-method.
- [ ] Types crossing isolation boundaries are `Sendable`. Prefer structs, which get it for free. `@unchecked Sendable` is a 🔴 blocker unless accompanied by a comment proving thread safety (e.g., internal lock).
- [ ] No `DispatchQueue`, no `DispatchGroup`, no completion-handler APIs where an async equivalent exists. Legacy callback APIs must be bridged with `withCheckedThrowingContinuation` — and check the continuation resumes exactly once on every path.
- [ ] `Task { }` inside ViewModels: check for unstructured task leaks. Long-running tasks stored in a property must be cancelled in `deinit` or when superseded (e.g., a new search cancels the previous one).
- [ ] `Task.detached` is almost always wrong — flag it and ask why it isn't a plain `Task` or an actor method.
- [ ] No blocking calls (`Thread.sleep`, synchronous I/O, `semaphore.wait`) inside async contexts.
- [ ] Shared mutable state outside the MainActor lives in an actor, not behind locks, unless there's a measured performance reason.
- [ ] Check cancellation: loops and long awaits in cancellable tasks should call `Task.checkCancellation()` or check `Task.isCancelled`.

Flutter mapping (one-liner for review comments): Dart has one isolate and no data races by default; Swift 6 makes the compiler enforce what Dart's runtime gave you for free — isolation annotations are the price.

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

## §6 Testing & testability

- [ ] New ViewModels come with unit tests using Swift Testing (`@Test`, `#expect`), not XCTest, for new test files.
- [ ] ViewModels are testable: dependencies injected as protocols, so tests inject fakes. If a ViewModel can't be constructed in a test without hitting the network, that's a 🟡 design finding.
- [ ] Async tests await real completion; no `sleep`-based synchronization.
- [ ] Tests assert behavior (state after action), not implementation details (which internal method was called).

## §7 Naming & style

- [ ] Swift API Design Guidelines: methods read as phrases (`insert(_:at:)`), booleans read as assertions (`isLoading`, `hasError`).
- [ ] ViewModels named `<Feature>ViewModel`, views `<Feature>View`, services `<Domain>Service` protocol + `Live<Domain>Service`/`Mock<Domain>Service` implementations.
- [ ] One primary type per file; file named after the type.
- [ ] No Flutter-isms leaking in: no `build()` helper methods returning views (use computed `var` or subviews), no `Widget`-style deeply nested initializer trees when modifiers do the job.
- [ ] `// MARK: -` sections in files over ~100 lines.
