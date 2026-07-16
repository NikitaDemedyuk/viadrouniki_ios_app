import Foundation

struct SingleResponse<T: Codable>: Codable {
    let data: T
}
