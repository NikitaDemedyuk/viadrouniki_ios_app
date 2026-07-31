---
name: ios-review
description: Review Swift/SwiftUI code in the viadrouniki_ios_app project against the project's architecture and Swift 6 strict concurrency rules. Use this skill whenever code is generated, modified, or reviewed in this project — including when the user asks to "review", "check", "audit", or "clean up" code, after any AI-generated Swift code is produced, before committing changes, or when the user asks whether code follows project conventions. Also use it when writing NEW Swift code in this project, so the code follows the conventions from the start.
---

# iOS Code Review — viadrouniki_ios_app

Review skill for a SwiftUI app with these fixed project decisions:

- **Minimum target:** iOS 18 (no availability checks needed below 18; prefer iOS 17/18 APIs over legacy equivalents)
- **Language mode:** Swift 6, strict concurrency enabled
- **Architecture:** MVVM with the Observation framework (`@Observable`), protocol-backed services, struct models
- **UI:** SwiftUI only. No UIKit unless wrapped and justified with a comment explaining why.

The team includes developers transitioning from Flutter. When explaining a finding, briefly map it to the Flutter/Dart equivalent where a natural mapping exists (e.g., `@Observable` ↔ ChangeNotifier, retain cycle ↔ no GC to save you). Keep these mappings to one sentence.

## Review workflow

Follow these steps in order. Do not skip step 1 — reviewing without building is guessing.

1. **Verify it compiles.** If a build environment is available, build (`xcodebuild build` or the project's build command) and run existing tests. If no build environment is available, state this explicitly at the top of the review and manually check for hallucinated APIs (see reference checklist §5).
2. **Check scope.** Compare the diff against the task it was supposed to accomplish. Flag any files or code added beyond the task scope — generated code often includes speculative helpers, unused abstractions, or duplicate logic that already exists elsewhere in the codebase. Search the codebase for existing equivalents before accepting new utilities.
3. **Run the layered checklist.** Read `references/swift-checklist.md` and apply every section to the changed code. Do not review from memory — the checklist encodes project decisions that override general Swift habits.
4. **Classify findings** using the severity levels below.
5. **Write the review** using the output format below.

## Severity levels

- 🔴 **Blocker** — must fix before merge: crashes, data races, retain cycles, force unwraps in production paths, hallucinated/nonexistent APIs, architecture violations (e.g., networking inside a View), `@ObservedObject`/`ObservableObject` used instead of `@Observable`.
- 🟡 **Should fix** — wrong but not dangerous: incorrect property wrapper choice that happens to work, missing `Sendable` annotations the compiler hasn't caught yet, side effects in `body`, `.onAppear` used for async work instead of `.task`, missing error handling on user-facing flows.
- 🟢 **Suggestion** — style, naming, decomposition of large views, testability improvements, more idiomatic Swift.

Do not pad reviews. If code is clean, say so in two sentences and stop. Never invent findings to appear thorough.

## Output format

ALWAYS use this exact template:

```
# Review: <file(s) or feature name>

**Build status:** <built and tests pass / built, N tests failing / could not build — reviewed statically>
**Scope check:** <matches task / includes out-of-scope additions: list them>

## Findings
### 🔴 Blockers
<numbered list, each with: file:line, what is wrong, why it matters, concrete fix. "None." if empty>
### 🟡 Should fix
<same format>
### 🟢 Suggestions
<same format, max 5 — pick the highest-value ones>

## Verdict
<one of: APPROVE / APPROVE AFTER FIXES / REQUEST CHANGES, with a one-sentence justification>
```

For each finding, show the fix as a short code snippet when it fits in under ~10 lines; otherwise describe it precisely.

## When writing new code (not just reviewing)

Apply the same checklist proactively. Before writing, read `references/swift-checklist.md` §1–§4 and follow the architecture layering rules exactly. New ViewModels are `@MainActor @Observable final class`; new services are protocols with a concrete implementation injected via initializer.
