import SwiftUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var isProfileLoginPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    accountRow
                }
                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.gray.gradient)
                                .frame(width: 32, height: 32)
                                .overlay {
                                    Image(systemName: "gear")
                                        .font(.system(size: 19, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                            Text("Settings")
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            // See `AppLanguage.localized(_:)` — this is the currently-visible
            // screen's own root title, and it needs the same pre-resolved
            // treatment as a pushed destination's: a plain `LocalizedStringKey`
            // literal here also goes stale on a language change.
            .navigationTitle(appViewModel.language.localized("Profile"))
            .sheet(isPresented: $isProfileLoginPresented) {
                ProfileLoginView()
            }
        }
    }

    /// Signed out the banner is a button opening the sign-in sheet; signed in it's
    /// inert, because there is no account-detail screen to push to yet.
    @ViewBuilder
    private var accountRow: some View {
        if appViewModel.isLoggedIn {
            banner(
                title: Text("Profile"),
                subtitle: Text("You are signed in."),
                showsChevron: false
            )
        } else {
            Button {
                isProfileLoginPresented = true
            } label: {
                banner(
                    title: Text("Sign in to Viadrouniki"),
                    subtitle: Text("Use Google to sign in."),
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func banner(title: Text, subtitle: Text, showsChevron: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                title
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                subtitle
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView()
        .environment(AppViewModel())
}
