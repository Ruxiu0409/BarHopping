import SwiftUI

extension EnvironmentValues {
    /// 在 Preview 或 App 內進一步減少動態效果，不覆寫唯讀的系統 accessibilityReduceMotion。
    /// 動畫元件採用 systemReduceMotion || appReduceMotion，false 不會取消使用者的系統偏好。
    @Entry var appReduceMotion = false
}
