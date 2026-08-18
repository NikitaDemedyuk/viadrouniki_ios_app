import SwiftUI

@main
struct ViadrounikiApp: App {
    @State private var appViewModel = AppViewModel()

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
