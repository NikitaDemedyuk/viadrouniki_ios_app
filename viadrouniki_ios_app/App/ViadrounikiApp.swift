import SwiftUI

@main
struct ViadrounikiApp: App {
    @State private var appViewModel: AppViewModel

    init() {
        #if DEBUG
        /// Injects a real bearer token so the signed-in Profile screens can be
        /// exercised against the live API while Google sign-in is still a stub.
        /// Set `VIADROUNIKI_DEBUG_TOKEN` in the scheme's own environment
        /// variables (Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Arguments) on an
        /// unshared scheme copy — never hardcode a token here or commit one.
        if let debugToken = ProcessInfo.processInfo.environment["VIADROUNIKI_DEBUG_TOKEN"] {
            AuthTokenStore.shared.token = debugToken
        }
        #endif
        _appViewModel = State(initialValue: AppViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                // Localizes every `LocalizedStringKey` below this point. API
                // content is a separate problem: each screen that fetches keys
                // its `.task` on `\.locale` so a language change refetches it.
                // Don't solve that with `.id()` here — it does refetch, but by
                // destroying the tree, which also drops every navigation path
                // and scroll position.
                .environment(\.locale, appViewModel.language.locale)
        }
    }
}
