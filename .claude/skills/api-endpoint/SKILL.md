---
name: api-endpoint
description: Add one new network call to viadrouniki_ios_app — either a new function in an existing Network/APIClient+<Domain>.swift extension, or a new extension file for a domain that doesn't have one yet. Use when the user asks to "add an endpoint", "call /v1/<path>", "add a fetch function for X", or a ViewModel needs data with no existing APIClient method for it. Narrower than feature-scaffold — use that instead if the user wants a whole new list screen, not just one call.
---

# Add an API endpoint — viadrouniki_ios_app

Every network call in this app goes through `APIClient` (`Network/APIClient.swift`), which owns the base URL, JSON decoding (custom ISO8601 date strategy), and error mapping. You are never adding raw `URLSession` calls — always a new method in an `extension APIClient`.

## Before writing anything

1. **Get the real endpoint path and response shape.** Ask for a sample JSON response (or the exact field list) if the user hasn't given one. Do not invent field names — a decode mismatch fails silently or crashes at runtime, not at compile time, so a fabricated shape is actively worse than asking.
2. **Check whether an `APIClient+<Domain>.swift` file already exists** for this domain (`Network/APIClient+Trips.swift`, `+Cars.swift`, `+Attractions.swift`, `+Auth.swift`). Add to the existing extension if there is one; only create a new file for a genuinely new domain.
3. **Figure out which shape this is** — see `references/patterns.md` for the exact template for each:
   - Paginated list with fixed/simple sort → pattern in `APIClient+Trips.swift`
   - Paginated list with a custom sort-field enum → pattern in `APIClient+Cars.swift`
   - Paginated list with an optional filter param (only appended when non-empty) → pattern in `APIClient+Attractions.swift`
   - Non-paginated GET returning a bare array (e.g. map pins) → `fetchAttractionsMap` in `APIClient+Attractions.swift`
   - Single-resource GET by id → `fetchCar(id:)` in `APIClient+Cars.swift`, using the `SingleResponse<T>` wrapper. `SingleResponse<T>` already exists in `Models/APIResponse.swift` — reuse it, never redeclare it.
   - Authenticated call with no params → `fetchCurrentUser` in `APIClient+Auth.swift`
   - POST — **there is no existing POST endpoint anywhere in this codebase yet** (login is currently a UI stub with no real network call). `APIClient.post<T,B>` exists and is ready to use, but treat a new POST call with more scrutiny than a GET: confirm the request body shape and auth requirement explicitly with the user rather than assuming, since there's no precedent to pattern-match here.

## Rules that apply to every new function

- **Locale**: any endpoint that returns user-facing localized text takes `locale: String = "ru"` and forwards it as a `locale` query param — this is the pattern in every existing GET except `fetchCurrentUser` (which has no localized content) and `fetchAttractionsMap`. Ask if you're not sure whether the new endpoint's response is localized.
- **Pagination**: reuse `PaginatedResponse<T>` / `PaginationMeta` (declared in `Models/APIResponse.swift`, alongside `SingleResponse<T>`) — never redeclare them. Page/perPage params follow the `page: Int = 1, perPage: Int = <endpoint-specific default>` shape.
- **Domain naming**: the network layer follows the *API's* resource name, not the app's model name — `APIClient+Attractions.swift` serves the `Point` model, `APIClient+Cars.swift` serves `Vehicle`. Match the file you're in; see the table in `CLAUDE.md`.
- **Auth**: pass `requiresAuth: true` to `get(url:requiresAuth:)` for anything that needs a logged-in user; omit it (defaults to `false`) otherwise. Don't add manual `Authorization` header code — `APIClient.get`/`post` already do this centrally.
- **Errors**: never add error handling in the new function itself. `APIClient.perform(_:)` already maps HTTP status codes and decode failures to `APIError` centrally — a new endpoint function should just be `let url = ...; return try await get(url: url)`, nothing more.
- **Query item ordering**: match the existing style in the file you're editing (some files put `page` last, some first) rather than picking a new convention — consistency within a file matters more than a "correct" universal order here.
- **Naming**: `fetch<Domain>s(...)` for a list, `fetch<Domain>(id:)` for a single resource, `fetch<Domain><Noun>(...)` for a sub-resource (e.g. `fetchCarTrips(id:)`).

## After writing

Build (`xcodebuild -scheme viadrouniki_ios_app -destination 'generic/platform=iOS Simulator' build`) to confirm the new function compiles against the real model types — this catches typos in field names against `Codable` types immediately since Swift's type checker will flag anything that doesn't line up. It does **not** catch decode-shape mismatches against the real API (wrong JSON key names, wrong nesting) — if you have a way to hit the real API (this app talks to `https://api.viadrouniki.by/v1`, no auth needed for public endpoints), `curl` the endpoint and diff the shape against your `CodingKeys` before calling it done.
