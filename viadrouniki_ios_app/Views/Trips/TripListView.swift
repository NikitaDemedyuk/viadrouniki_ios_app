import SwiftUI

struct TripListView: View {
    var body: some View {
        NavigationStack {
            Text("Trips")
                .navigationTitle("Trips")
        }
    }
}

#Preview {
    TripListView()
}
