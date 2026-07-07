import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        TabView {
            TripListView()
                .tabItem { Label("Trips", systemImage: "map") }

            PointsView()
                .tabItem { Label("Points", systemImage: "mappin.and.ellipse") }

            VehicleListView()
                .tabItem { Label("Vehicles", systemImage: "car") }

            if appViewModel.isLoggedIn {
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            } else {
                LoginView()
                    .tabItem { Label("Login", systemImage: "person.badge.key") }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
