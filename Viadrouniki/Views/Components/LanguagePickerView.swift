import SwiftUI

/// Lets the user choose the language the app is presented in.
///
/// This exists because the system language can't be relied on: iOS ships no
/// Belarusian display language, so a user can neither add it to their preferred
/// languages nor reach it through the per-app language picker in Settings.
/// See `AppLanguage`.
struct LanguagePickerView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        @Bindable var appViewModel = appViewModel

        Picker("Language", selection: $appViewModel.language) {
            ForEach(AppLanguage.allCases) { language in
                // Verbatim: each language is named in its own tongue, so these
                // must not be translated into the currently selected one.
                Text(verbatim: language.nativeName)
                    .tag(language)
            }
        }
    }
}

#Preview {
    Form {
        LanguagePickerView()
    }
    .environment(AppViewModel())
}
