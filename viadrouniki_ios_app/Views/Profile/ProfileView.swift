import SwiftUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var viewModel = ProfileViewModel()
    @State private var isProfileLoginPresented = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    accountRow
                    if let message = viewModel.errorMessage, viewModel.user == nil {
                        ErrorBannerView(message: message) { await load() }
                    }
                }

                Section {
                    if appViewModel.isLoggedIn {
                        myCarsRow
                    }
                    settingsRow
                }

                /// The token lives in the Keychain, which survives app deletion,
                /// so without this row a signed-in user has no way back out.
                if appViewModel.isLoggedIn {
                    Section {
                        Button("Sign out", role: .destructive) {
                            appViewModel.logout()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            /// See `AppLanguage.localized(_:)` — this is the currently-visible
            /// screen's own root title, and it needs the same pre-resolved
            /// treatment as a pushed destination's: a plain `LocalizedStringKey`
            /// literal here also goes stale on a language change.
            .navigationTitle(appViewModel.language.localized("Profile"))
            .refreshable { await load() }
            .navigationDestination(for: Vehicle.self) { vehicle in
                VehicleDetailView(vehicle: vehicle)
            }
            .sheet(isPresented: $isProfileLoginPresented) {
                ProfileLoginView()
            }
        }
        /// Keyed on `isLoggedIn`, not `\.locale` — neither request takes a
        /// `locale` param or returns server-localized text. See CLAUDE.md.
        .task(id: appViewModel.isLoggedIn) {
            if appViewModel.isLoggedIn {
                await load()
            } else {
                viewModel.clear()
            }
        }
    }

    /// Sequences both fetches with the one error the screen acts on rather than
    /// displays. Lives in the View because flipping `isLoggedIn` is
    /// `AppViewModel`'s job, and a ViewModel must not reach up to it.
    private func load() async {
        guard appViewModel.isLoggedIn else { return }
        async let profile: Void = viewModel.load()
        async let cars: Void = viewModel.loadCars()
        _ = await (profile, cars)
        /// Checked once, after both settle, so a stale token signs out exactly
        /// once no matter which request noticed first.
        if viewModel.sessionExpired {
            appViewModel.logout()
        }
    }

    /// Signed out the banner is a button opening the sign-in sheet; signed in it
    /// pushes the account screen, but only once there's an account to show.
    @ViewBuilder
    private var accountRow: some View {
        if appViewModel.isLoggedIn {
            if let user = viewModel.user {
                NavigationLink {
                    ProfileAccountView(user: user)
                } label: {
                    ProfileBannerRow(user: user)
                }
            } else {
                /// Inert while loading or after a failure — pushing an account
                /// screen with no account to show would be worse than waiting.
                ProfileBannerRow(user: nil)
                    .overlay(alignment: .trailing) {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                    }
            }
        } else {
            Button {
                isProfileLoginPresented = true
            } label: {
                signInBanner
            }
            .buttonStyle(.plain)
        }
    }

    private var signInBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Sign in to Viadrouniki")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Use Google to sign in.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    /// Not wired up yet — no dedicated cars screen exists. Placeholder row,
    /// styled like `settingsRow`, with an empty action until that screen and
    /// its navigation are built.
    private var myCarsRow: some View {
        Button {
        } label: {
            HStack {
                iconRow(systemImage: "car.fill", tint: .blue, title: "My cars")
                Spacer()
                /// `NavigationLink` draws this automatically; this row is a
                /// plain `Button` since there's no destination yet, so it's
                /// added by hand to match `settingsRow`'s look.
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var settingsRow: some View {
        NavigationLink {
            SettingsView()
        } label: {
            iconRow(systemImage: "gear", title: "Settings")
        }
    }

    private func iconRow(systemImage: String, tint: Color = .gray, title: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.gradient)
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: systemImage)
                        .font(.system(size: 19, weight: .medium))
                        .foregroundStyle(.white)
                }
            Text(title)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppViewModel())
}
