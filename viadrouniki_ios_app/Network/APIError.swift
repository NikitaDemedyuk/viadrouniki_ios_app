import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    /// Resolved against `AppLanguage.current` rather than `Locale.current`: these
    /// strings are built outside SwiftUI, so the `\.locale` environment value the
    /// rest of the UI reads doesn't reach them, and the device language is not the
    /// app's language (iOS has no Belarusian).
    ///
    /// `bundle:` is what selects the language — `locale:` alone does not, it only
    /// formats the interpolated values. See `AppLanguage.bundle`.
    var errorDescription: String? {
        let language = AppLanguage.current
        let bundle = language.bundle
        let locale = language.locale
        switch self {
        case .unauthorized:
            return String(localized: "Unauthorized. Please log in again.", bundle: bundle, locale: locale)
        case .serverError(let code):
            return String(localized: "Server error (\(code)).", bundle: bundle, locale: locale)
        case .decodingError(let error):
            return String(localized: "Failed to parse response: \(error.localizedDescription)", bundle: bundle, locale: locale)
        case .networkError(let error):
            return String(localized: "Network error: \(error.localizedDescription)", bundle: bundle, locale: locale)
        }
    }
}

extension Error {
    /// The message to show the user, or `nil` when there is nothing worth
    /// showing.
    ///
    /// SwiftUI cancels a `.task` when its view goes away, which surfaces here
    /// as `APIError.networkError(URLError(.cancelled))` — noise, not a failure
    /// the user should read. The cancellation arrives wrapped, so `catch is
    /// CancellationError` won't match it; ask the task instead.
    var presentableMessage: String? {
        Task.isCancelled ? nil : localizedDescription
    }
}
