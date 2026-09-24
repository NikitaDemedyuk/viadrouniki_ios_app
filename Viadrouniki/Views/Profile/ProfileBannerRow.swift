import SwiftUI

/// The Apple-Account-style top row of the Profile tab: avatar, name, secondary
/// line. `user == nil` is the signed-in-but-not-loaded-yet state.
struct ProfileBannerRow: View {
    let user: AppUser?

    var body: some View {
        HStack(spacing: 16) {
            UserAvatarView(url: user?.mainPhoto?.url, size: 60)
            VStack(alignment: .leading, spacing: 2) {
                titleText
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                subtitleText
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
    }

    /// `Text(name)`/`Text(email)` take a `String` variable, so they render
    /// verbatim rather than looking up a catalog key — correct here, since the
    /// server already localized that text.
    private var titleText: Text {
        if let name = user?.displayName {
            Text(name)
        } else {
            Text("Account")
        }
    }

    private var subtitleText: Text {
        if let email = user?.email {
            Text(email)
        } else {
            Text("You are signed in.")
        }
    }
}
