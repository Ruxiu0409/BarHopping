import SwiftUI

/// 自訂卡片、chip 與自繪按鈕的按壓回饋。不取代 bordered、toolbar、Menu 等原生樣式。
/// 按下立即反應，放開才回彈；不延遲 action、不攔截手勢、不自動產生觸覺回饋。
struct AppPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && isEnabled && !reduceMotion ? 0.98 : 1)
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
            .animation(
                configuration.isPressed ? nil : AppMotion.resolved(AppMotion.tap, reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}
