import SwiftUI

private struct AppSymbolReplacementModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    let value: Value

    func body(content: Content) -> some View {
        content
            .contentTransition(reduceMotion ? .opacity : .symbolEffect(.replace))
            .appAnimation(AppMotion.tap, value: value)
    }
}

extension View {
    /// 用於同一個 Image 的 heart/heart.fill、選取勾號替換，value 傳圖示名稱或選取值。
    func appSymbolReplacement<Value: Equatable>(value: Value) -> some View {
        modifier(AppSymbolReplacementModifier(value: value))
    }
}
