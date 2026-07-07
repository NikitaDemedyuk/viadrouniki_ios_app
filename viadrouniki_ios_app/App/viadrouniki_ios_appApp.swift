import SwiftUI

@main
struct viadrouniki_ios_appApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
        }
    }
}
