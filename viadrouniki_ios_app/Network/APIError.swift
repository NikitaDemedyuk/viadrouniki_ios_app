import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:               return "Unauthorized. Please log in again."
        case .serverError(let code):      return "Server error (\(code))."
        case .decodingError(let error):   return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):    return "Network error: \(error.localizedDescription)"
        }
    }
}
