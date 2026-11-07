import SwiftUI

struct OnboardingHero: View {
    let symbol: String
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize: CGFloat = 52

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: symbolSize, weight: .light))
            .foregroundStyle(AppTheme.accentOnDark)
            .padding(28)
            .modifier(OnboardingSurface())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .accessibilityHidden(true)
    }
}
