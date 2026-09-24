import Foundation

protocol PhotoResource: Identifiable {
    var url: URL { get }
    var urlMobile: URL { get }
    var isMain: Bool? { get }
}
