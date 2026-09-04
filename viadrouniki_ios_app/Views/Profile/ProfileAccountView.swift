import SwiftUI

/// The pushed account-detail screen, laid out the way the Settings app lays out
/// its Apple Account screen.
///
/// Takes the user as a seed and never refetches: `auth/me` is the only endpoint
/// that returns it, so the value handed in *is* the full payload. `ProfileView`
/// owns the request and its `.refreshable` covers staleness.
struct ProfileAccountView: View {
    let user: AppUser

    @Environment(AppViewModel.self) private var appViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            personalSection
            linkedAccountsSection
            notificationsSection
        }
        .listStyle(.insetGrouped)
        /// See `AppLanguage.localized(_:)` — a `LocalizedStringKey` literal here
        /// goes stale on a language change for whichever screen is on-screen.
        .navigationTitle(appViewModel.language.localized("Account"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            UserAvatarView(url: user.mainPhoto?.url, size: 96)
            if let name = user.displayName {
                Text(name)
                    .font(.title2.bold())
            }
            if let email = user.email {
                Text(email)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var personalSection: some View {
        Section {
            if let name = user.displayName {
                LabeledContent("Name") { Text(name) }
            }
            if let email = user.email {
                LabeledContent("Email") { Text(email) }
            }
        } header: {
            Text("Personal info")
        } footer: {
            if user.email != nil, !user.isEmailVerified {
                Text("This email address hasn't been verified yet.")
            }
        }
    }

    private var linkedAccountsSection: some View {
        Section {
            telegramRow
            instagramRow
        } header: {
            Text("Linked accounts")
        }
    }

    /// Brand names are identical in ru and be, so they're verbatim rather than
    /// two pointless catalog keys. Same reasoning as `LanguagePickerView`.
    @ViewBuilder
    private var telegramRow: some View {
        if user.isTelegramLinked,
            let username = user.telegramUsername,
            let url = URL(string: "https://t.me/\(username)")
        {
            linkRow(title: Text(verbatim: "Telegram"), value: Text(verbatim: "@\(username)"), url: url)
        } else {
            LabeledContent { Text("Not linked") } label: { Text(verbatim: "Telegram") }
        }
    }

    @ViewBuilder
    private var instagramRow: some View {
        if let handle = user.instagramHandle,
            let url = URL(string: "https://www.instagram.com/\(handle)")
        {
            linkRow(title: Text(verbatim: "Instagram"), value: Text(verbatim: "@\(handle)"), url: url)
        } else {
            LabeledContent { Text("Not linked") } label: { Text(verbatim: "Instagram") }
        }
    }

    private func linkRow(title: Text, value: Text, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack {
                title
                    .foregroundStyle(.primary)
                Spacer()
                value
                    .foregroundStyle(.secondary)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var notificationsSection: some View {
        if let settings = user.settings {
            Section {
                LabeledContent("Daily digest") { stateText(settings.dailyDigestTelegram) }
                LabeledContent("Telegram alerts") { stateText(settings.notificationsTelegram) }
            } header: {
                Text("Notifications")
            } footer: {
                Text("These settings can be changed on viadrouniki.by.")
            }
        }
    }

    /// Read-only on purpose: there is no endpoint to write these back, and the
    /// app has no POST call sites at all. A `Toggle` that refuses to move reads
    /// as a bug, and one that silently does nothing is worse.
    ///
    /// Two separate `Text` literals, **not** `Text(isOn ? "On" : "Off")` — a
    /// ternary of two literals binds to the `StringProtocol` overload and would
    /// render the English key verbatim.
    private func stateText(_ isOn: Bool?) -> Text {
        isOn == true ? Text("On") : Text("Off")
    }
}
