import SwiftUI

struct SplashView: View {
    var body: some View {
        Color("splashBackground")
            .ignoresSafeArea()
            .overlay {
                /// Unresized, matching how `UILaunchScreen`'s `UIImageName` draws the same
                /// asset on the native launch screen — its own SVG canvas already sizes the
                /// glyph (see `make-app-icon.py`), so scaling the `Image` here a second time
                /// would shrink the glyph relative to the canvas.
                Image("splashLogo")
                    /// Nudges the glyph up to line up with the native launch screen. Verified
                    /// by pixel-diffing screenshots of both screens (`xcrun simctl io
                    /// screenshot`): with no offset the two glyphs are pixel-identical in size
                    /// but this one lands exactly 42px (14pt at this device's 3x scale) lower
                    /// than the native screen's, for reasons that didn't trace back to safe
                    /// area insets (they measured zero at this overlay). Re-verify the same
                    /// way if this ever visibly drifts.
                    .offset(y: -14)
            }
    }
}

#Preview {
    SplashView()
}
