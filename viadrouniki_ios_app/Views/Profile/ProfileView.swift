import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Form {
                LanguagePickerView()
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppViewModel())
}
