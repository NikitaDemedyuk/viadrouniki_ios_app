Review the current file or selected code as an experienced iOS engineer. Check for:

**Correctness**
- Logic bugs, force unwraps (`!`) that could crash, incorrect optionals handling
- Missing error handling at system boundaries (network, decoding, Keychain)
- Race conditions or data races with async/await
- Memory leaks (strong reference cycles in closures, delegates)

**SwiftUI & Architecture**
- State management: is `@State`, `@Binding`, `@StateObject`, `@ObservedObject` used correctly?
- Are ViewModels properly separated from Views?
- Does the view body do work it shouldn't (heavy computation, side effects)?
- Unnecessary redraws from poorly scoped state

**API & Networking (viadrouniki.by)**
- Correct use of `APIClient` — is the right endpoint called?
- Is the `locale` parameter passed for localization?
- Are responses decoded against the real API shape (snake_case → camelCase via `CodingKeys`)?
- Auth token attached where required (`canAcceptApplications`, bookings)

**Swift Best Practices**
- Prefer `let` over `var` where value never changes
- Avoid `class` when `struct` suffices
- No unused variables, dead code, or redundant type annotations
- Naming follows Swift API design guidelines (camelCase properties, PascalCase types)

**iOS-specific**
- Images use `url_mobile` on iPhone, `url` on iPad
- Date formatting uses the user's locale, not hardcoded
- Accessibility: interactive elements have labels

Report findings grouped by severity: **Error** (must fix) → **Warning** (should fix) → **Suggestion** (nice to have). Skip categories with no findings.
