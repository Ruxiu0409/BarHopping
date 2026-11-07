import SwiftUI

/// 引導專用的展示卡片，沿用全 App 的玻璃材質。
struct OnboardingSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .appGlassCard(cornerRadius: 28)
    }
}
