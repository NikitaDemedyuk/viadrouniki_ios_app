import SwiftUI

/// A circular avatar for a user's `main_photo`.
///
/// Deliberately not built on `PhotoHeroView`/`PhotoResource`: `auth/me`'s
/// `main_photo` carries only `id`/`url`/`alt` — no `url_mobile`, no `is_main` —
/// so `UserPhoto` can't conform, and `PhotoHeroView` is a fixed 280pt full-bleed
/// hero rather than a circular avatar.
struct UserAvatarView: View {
    let url: URL?
    var size: CGFloat = 60

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.secondary)
        }
        .frame(width: size, height: size)
        .clipped()
        .clipShape(.circle)
    }
}
