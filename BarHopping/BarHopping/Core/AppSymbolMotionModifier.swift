import SwiftUI

private struct AppSymbolMotionModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    let trigger: Value

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content.contentTransition(.opacity)
        } else {
            content
                .symbolEffect(.bounce, options: .nonRepeating, value: trigger)
        }
    }
}

extension View {
    /// 只套在 Image(systemName:) 的單次成功／完成圖示；trigger 用成功事件序號，不用載入或滾動狀態。
    /// 若同時需要圖示替換，擇一使用 appSymbolReplacement，避免 bounce 與 replace 疊加。
    func appSymbolBounce<Value: Equatable>(trigger: Value) -> some View {
        modifier(AppSymbolMotionModifier(trigger: trigger))
    }
}
