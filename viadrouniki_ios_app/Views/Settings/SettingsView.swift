import SwiftUI

struct SettingsView: View {
    // See `AppLanguage.localized(_:)` — `.navigationTitle` on this screen needs
    // it pre-resolved off `appViewModel.language`, not handed a
    // `LocalizedStringKey` literal. Do **not** reach for `.id()` instead — that
    // changes the destination's identity and pops the user back to Profile.
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        Form {
            LanguagePickerView()
        }
        .navigationTitle(appViewModel.language.localized("Settings"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppViewModel())
}
