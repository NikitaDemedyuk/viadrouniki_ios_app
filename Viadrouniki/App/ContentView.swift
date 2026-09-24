import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        @Bindable var appViewModel = appViewModel

        // Tab item labels are `.tabItem`-bridged, same UIKit staleness as
        // `.navigationTitle` — see `AppLanguage.localized(_:)`. Evidenced
        // directly: after a language switch, the three background tabs picked
        // up the new language but the active tab's own label and title didn't.
        TabView(selection: $appViewModel.selectedTab) {
            TripListView()
                .tabItem {
                    Label(appViewModel.language.localized("Trips"), systemImage: "map")
                }
                .tag(0)

            PointsView()
                .tabItem {
                    Label(appViewModel.language.localized("Points"), systemImage: "mappin.and.ellipse")
                }
                .tag(1)

            VehicleListView()
                .tabItem {
                    Label(appViewModel.language.localized("Cars"), systemImage: "car")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label(appViewModel.language.localized("Profile"), systemImage: "person.crop.circle")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
