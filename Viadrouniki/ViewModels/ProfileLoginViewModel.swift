import Foundation
import Observation

@Observable
@MainActor
final class ProfileLoginViewModel {
    var isSigningIn = false
    var errorMessage: String?

    /// Google sign-in is not wired up yet, and cannot be from inside this app.
    ///
    /// The backend's `GET /v1/auth/google/redirect` is a web-only flow: its
    /// `redirect_uri` is hardcoded to `api.viadrouniki.by`, the final hop lands on
    /// `viadrouniki.by/auth/callback`, and the endpoint ignores any `redirect` /
    /// `state` parameter, so there is no way to hand the token back to the app.
    /// `viadrouniki.by` serves no apple-app-site-association either, so a Universal
    /// Link callback isn't available as a fallback.
    ///
    /// Once the backend final-redirects to a whitelisted custom scheme, replace the
    /// body below with an `ASWebAuthenticationSession` against
    /// `viadrouniki://auth/callback` and finish with `AppViewModel.login(token:)`.
    /// No third-party SDK is needed for that.
    func signInWithGoogle() async {
        guard !isSigningIn else { return }
        isSigningIn = true
        defer { isSigningIn = false }

        // Resolved against `AppLanguage.current` rather than `Locale.current`:
        // built outside SwiftUI, so `\.locale` doesn't reach it. `bundle:` is what
        // selects the language — `locale:` alone only formats interpolations.
        errorMessage = String(
            localized: "Google sign-in isn't available yet.",
            bundle: AppLanguage.current.bundle,
            locale: AppLanguage.current.locale
        )
    }
}
