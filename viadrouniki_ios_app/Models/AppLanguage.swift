import Foundation

/// The languages the app ships UI text in.
///
/// iOS has no Belarusian display language — it isn't in the system's language
/// list, so a user can't add it to their preferred languages and the per-app
/// language picker can't offer it either. The system language is therefore
/// deliberately *not* consulted: the app carries its own selection and forces it
/// onto the view tree via `\.locale`. See `LanguagePickerView`.
/// `nonisolated` because the project sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`,
/// which would otherwise make this main-actor-isolated — and `APIClient` reads
/// `current` from default argument values, which are evaluated in a nonisolated
/// context. `UserDefaults` is thread-safe, so there is nothing to protect here.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case belarusian = "be"

    var id: String { rawValue }

    /// Drives SwiftUI's `LocalizedStringKey` lookup, via `\.locale` on the view tree.
    var locale: Locale { Locale(identifier: rawValue) }

    /// The `.lproj` bundle holding this language's strings.
    ///
    /// Needed because `String(localized:locale:)` does **not** use `locale` to pick
    /// the translation — that argument only formats interpolated values, while the
    /// lookup itself goes through the *device's* preferred localization. Passing
    /// `bundle:` is what actually selects the language outside SwiftUI. Falls back
    /// to `.main` so a missing `.lproj` degrades to the old behaviour rather than
    /// trapping.
    var bundle: Bundle {
        Bundle.main.path(forResource: rawValue, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
    }

    /// The API's `locale` query param. A passthrough rather than a mapping table
    /// because the API happens to use the same codes as the bundle localizations.
    var apiLocale: String { rawValue }

    /// Shown in the picker — each name written in its own language, not the
    /// currently selected one, so either option is readable to either audience.
    var nativeName: String {
        switch self {
        case .russian:    "Русский"
        case .belarusian: "Беларуская"
        }
    }

    private static let defaultsKey = "AppLanguage"

    /// The single source of truth for the selected language, defaulting to Russian.
    ///
    /// A static rather than a property on `AppViewModel` because `APIClient` reads
    /// it for the `locale` query param, and the dependency direction
    /// (View → ViewModel → APIClient) forbids the client reaching back up.
    static var current: AppLanguage {
        get {
            UserDefaults.standard.string(forKey: defaultsKey)
                .flatMap(AppLanguage.init(rawValue:)) ?? .russian
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }
}
