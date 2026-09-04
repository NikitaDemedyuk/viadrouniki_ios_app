import Foundation

/// The signed-in user, as returned by `auth/me`.
///
/// Only the fields the Profile tab displays are modelled. `roles`, `permissions`,
/// `car_limit`, `car_photos_limit`, `media_upload_max_size_kb`, `main_photo_id`,
/// `is_active`, `is_approved`, `created_at` and `updated_at` are deliberately
/// dropped: `Codable` ignores unknown keys, so every field modelled is one more
/// field that can fail the decode. Add them when something shows them.
struct AppUser: Identifiable, Codable, Hashable {
    let id: Int
    /// Optional to match `VehicleOwner`, which models the same backend user
    /// object's `first_name`/`last_name`/`name` as optional — direct evidence
    /// the API emits nulls for them. Widening never fails a decode; narrowing can.
    let firstName: String?
    let lastName: String?
    let name: String?
    let email: String?
    let instagram: String?
    let mainPhoto: UserPhoto?
    /// Deliberately `String?`, never `Date?`. The shared decoder demands ISO8601
    /// *with fractional seconds* and a wrongly-formatted date fails the whole
    /// response — which here would break the profile screen only for users who
    /// have verified their email, i.e. invisibly in testing. This field is `null`
    /// in every sample we have, so its non-null format is unverified. Nothing
    /// needs the value, only its nullity; see `isEmailVerified`.
    let emailVerifiedAt: String?
    let settings: UserSettings?
    let telegramLinked: Bool?
    let telegramUsername: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, instagram, settings
        case firstName = "first_name"
        case lastName = "last_name"
        case mainPhoto = "main_photo"
        case emailVerifiedAt = "email_verified_at"
        case telegramLinked = "telegram_linked"
        case telegramUsername = "telegram_username"
    }
}

extension AppUser {
    /// `name` when the API sends one, otherwise the first/last pair joined.
    var displayName: String? {
        if let name, !name.isEmpty { return name }
        let parts = [firstName, lastName].compactMap(\.self).filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    var isEmailVerified: Bool { emailVerifiedAt != nil }

    var isTelegramLinked: Bool { telegramLinked == true }

    /// The handle without its leading `@`, ready to interpolate into a profile
    /// URL — the same normalisation `VehicleDetailView` does for an owner.
    var instagramHandle: String? {
        instagram?.trimmingCharacters(in: CharacterSet(charactersIn: "@"))
    }
}

/// `auth/me`'s `main_photo` carries only `id`/`url`/`alt` — no `url_mobile`, no
/// `is_main` — so it can't conform to `PhotoResource`. Same call `TripCarPhoto`
/// makes for the same reason.
struct UserPhoto: Identifiable, Codable, Hashable {
    let id: Int
    let url: URL
    let alt: String?
}

/// Optional at both levels so a key the backend stops sending can't fail the
/// whole decode. Read-only in the app — there is no endpoint to write them back.
struct UserSettings: Codable, Hashable {
    let dailyDigestTelegram: Bool?
    let notificationsTelegram: Bool?

    enum CodingKeys: String, CodingKey {
        case dailyDigestTelegram = "daily_digest_telegram"
        case notificationsTelegram = "notifications_telegram"
    }
}
