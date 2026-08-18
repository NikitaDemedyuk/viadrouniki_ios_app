import SwiftUI

@main
struct ViadrounikiApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
                .environment(\.locale, appViewModel.language.locale)
                // Rebuilds the tree on a language change, which recreates the
                // `@State` ViewModels and re-runs their `.task`s — that's what
                // refetches API content in the newly selected locale.
                .id(appViewModel.language)
        }
    }
}
