import SwiftUI

/// 引導專用的展示卡片，沿用全 App 的深色微漸層卡片樣式。
struct OnboardingSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appGradientCard(cornerRadius: 28)
    }
}
