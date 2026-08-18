import SwiftUI

struct LoginView: View {
    var body: some View {
        NavigationStack {
            Form {
                // Also offered here, not just in Profile: the Profile tab only
                // exists once logged in, so this is the sole way a logged-out
                // user can reach the language setting.
                LanguagePickerView()
            }
            .navigationTitle("Login")
        }
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
