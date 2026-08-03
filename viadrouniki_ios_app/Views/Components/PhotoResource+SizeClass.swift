import SwiftUI

extension PhotoResource {
    /// The variant to load for the given horizontal size class: the full-size
    /// asset on regular, the mobile one everywhere else.
    func url(for sizeClass: UserInterfaceSizeClass?) -> URL {
        sizeClass == .regular ? self.url : self.urlMobile
    }
}
