import SwiftUI

private struct AppNumericTextModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    let value: Value
    let countsDown: Bool

    func body(content: Content) -> some View {
        content
            .contentTransition(reduceMotion ? .opacity : .numericText(countsDown: countsDown))
            .appAnimation(AppMotion.tap, value: value)
    }
}

extension View {
    /// 用在 Text 的站數、讚數與額度，value 傳實際數值；不對定位座標、每幀計時或編輯中的輸入使用。
    func appNumericText<Value: Equatable>(value: Value, countsDown: Bool = false) -> some View {
        modifier(AppNumericTextModifier(value: value, countsDown: countsDown))
    }
}
