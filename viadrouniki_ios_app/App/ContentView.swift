import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        @Bindable var appViewModel = appViewModel

        TabView(selection: $appViewModel.selectedTab) {
            TripListView()
                .tabItem { Label("Trips", systemImage: "map") }
                .tag(0)

            PointsView()
                .tabItem { Label("Points", systemImage: "mappin.and.ellipse") }
                .tag(1)

            VehicleListView()
                .tabItem { Label("Vehicles", systemImage: "car") }
                .tag(2)

            if appViewModel.isLoggedIn {
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                    .tag(3)
            } else {
                LoginView()
                    .tabItem { Label("Login", systemImage: "person.badge.key") }
                    .tag(3)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
