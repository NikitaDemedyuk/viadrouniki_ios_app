import SwiftUI

struct VehicleListView: View {
    var body: some View {
        NavigationStack {
            Text("Vehicles")
                .navigationTitle("Vehicles")
        }
    }
}

#Preview {
    VehicleListView()
}
