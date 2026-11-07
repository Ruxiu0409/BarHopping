import SwiftUI

private struct AppAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    let animation: Animation
    let value: Value

    func body(content: Content) -> some View {
        content
            .animation(AppMotion.resolved(animation, reduceMotion: reduceMotion), value: value)
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
            }
    }
}

extension View {
    /// 限定在會變動的最小容器，追蹤選取值、狀態 enum 或 ID 陣列；不要放在 TabView 根層。
    func appAnimation<Value: Equatable>(_ animation: Animation = AppMotion.reveal, value: Value) -> some View {
        modifier(AppAnimationModifier(animation: animation, value: value))
    }
}
