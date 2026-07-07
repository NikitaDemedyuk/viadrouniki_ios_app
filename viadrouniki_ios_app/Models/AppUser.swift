import Foundation

struct AppUser: Identifiable, Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let email: String?
    let instagram: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, name, email, instagram
        case firstName = "first_name"
        case lastName  = "last_name"
    }
}
