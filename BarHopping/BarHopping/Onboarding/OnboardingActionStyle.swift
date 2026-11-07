import SwiftUI

struct OnboardingActionStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.buttonStyle(.borderedProminent).buttonBorderShape(.capsule)
        } else {
            content.buttonStyle(.glassProminent).buttonBorderShape(.capsule)
        }
    }
}
