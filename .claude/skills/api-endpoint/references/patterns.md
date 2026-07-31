# Endpoint patterns — copy the one that matches, don't invent a new shape

## Paginated list, fixed sort (`APIClient+Trips.swift`)

```swift
func fetch<Domain>s(
    page: Int = 1,
    perPage: Int = 18,
    sortOrder: SortOrder = .desc,
    locale: String = "ru"
) async throws -> PaginatedResponse<<Domain>> {
    let url = baseURL
        .appending(path: "<endpoint>")
        .appending(queryItems: [
            URLQueryItem(name: "page",       value: "\(page)"),
            URLQueryItem(name: "per_page",   value: "\(perPage)"),
            URLQueryItem(name: "sort_by",    value: "<field>"),
            URLQueryItem(name: "sort_order", value: sortOrder.rawValue),
            URLQueryItem(name: "locale",     value: locale)
        ])
    return try await get(url: url)
}
```

## Paginated list, custom sort-field enum (`APIClient+Cars.swift`)

```swift
enum <Domain>SortField: String {
    case <field1>
    case <field2> = "<api_value>"   // give the raw value explicitly when the API's
                                     // query value differs from your Swift case name
}

func fetch<Domain>s(
    page: Int,
    perPage: Int = 18,
    sortBy: <Domain>SortField = .<field1>,
    sortOrder: SortOrder = .asc
) async throws -> PaginatedResponse<<Domain>> {
    let url = baseURL
        .appending(path: "<endpoint>")
        .appending(queryItems: [
            URLQueryItem(name: "sort_by", value: sortBy.rawValue),
            URLQueryItem(name: "sort_order", value: sortOrder.rawValue),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
            URLQueryItem(name: "page", value: "\(page)"),
        ])
    return try await get(url: url)
}
```

Only declare a new `SortField` enum if the domain genuinely has multiple sortable fields the UI exposes (like Vehicles' brand/year/trips picker). If there's just one natural sort, use the fixed-sort pattern above instead — don't build a picker-ready enum nobody asked for.

## Paginated list with an optional filter param (`APIClient+Attractions.swift`)

Use this when a query param should only be sent when it has a value (rather than always sending an empty string):

```swift
func fetch<Domain>s(
    page: Int,
    perPage: Int = 20,
    search: String = "",
    locale: String = "ru"
) async throws -> PaginatedResponse<<Domain>> {
    var queryItems: [URLQueryItem] = [
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "locale", value: locale),
        URLQueryItem(name: "page", value: "\(page)"),
    ]
    if !search.isEmpty {
        queryItems.append(URLQueryItem(name: "search", value: search))
    }
    let url = baseURL
        .appending(path: "<endpoint>")
        .appending(queryItems: queryItems)
    return try await get(url: url)
}
```

## Non-paginated GET returning a bare array (`fetchAttractionsMap`)

For endpoints that intentionally return everything at once (e.g. map pins, where pagination doesn't make sense):

```swift
func fetch<Domain>Map(
    locale: String = "ru"
) async throws -> [<Domain>MapItem] {
    let url = baseURL
        .appending(path: "<endpoint>/map")
        .appending(queryItems: [
            URLQueryItem(name: "locale", value: locale),
        ])
    return try await get(url: url)
}
```

## Single resource by id

Not present on `develop` as of this writing — this existed on `feature/vehicle-page`. Check `Models/APIResponse.swift` or the top of `Models/Trip.swift` for `SingleResponse<T>` before adding it again:

```swift
// Only add this if it doesn't already exist somewhere in Models/:
struct SingleResponse<T: Codable>: Codable {
    let data: T
}
```

```swift
func fetch<Domain>(id: Int) async throws -> <Domain> {
    let url = baseURL.appending(path: "<endpoint>/\(id)")
    let response: SingleResponse<<Domain>> = try await get(url: url)
    return response.data
}
```

## Authenticated call, no params (`fetchCurrentUser`)

```swift
func fetch<Thing>() async throws -> <Model> {
    try await get(url: baseURL.appending(path: "<endpoint>"), requiresAuth: true)
}
```

## POST (no existing precedent — confirm shape with the user first)

`APIClient.post<T,B>` already exists and attaches the auth token automatically if one is present:

```swift
struct <Domain>Request: Encodable {
    let <field>: String
}

func create<Domain>(_ request: <Domain>Request) async throws -> <Domain> {
    let url = baseURL.appending(path: "<endpoint>")
    return try await post(url: url, body: request)
}
```

Confirm with the user: does this endpoint require auth (it will send the token automatically if `AuthTokenStore.shared.token` is set — there's currently no way to opt out of that in `post`, unlike `get`'s explicit `requiresAuth` flag)? What's the exact request body shape? Does the response return the created resource, or something else (e.g. just a success flag)? Don't guess any of these.
