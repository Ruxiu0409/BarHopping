import SwiftUI

private struct AppTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    let kind: AppMotion.Transition

    func body(content: Content) -> some View {
        content.transition(AppMotion.transition(kind, reduceMotion: reduceMotion))
    }
}

extension View {
    /// 放在 if/ForEach 的子項目；父容器搭配 appAnimation，或在修改狀態時用 withAppAnimation。
    /// 只宣告 transition 不會自行觸發動畫。減少動態效果只保留 opacity，搭配 appAnimation 則立即更新。
    func appTransition(_ kind: AppMotion.Transition = .reveal) -> some View {
        modifier(AppTransitionModifier(kind: kind))
    }
}
