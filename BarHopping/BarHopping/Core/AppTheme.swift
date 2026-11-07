import SwiftUI

/// 全 App 共用的深色系配色。App 一律以深色模式呈現（ContentView 設定 preferredColorScheme(.dark)）。
/// 各分頁的 *Theme 檔請引用這裡的顏色，不要各自定義另一套底色。
enum AppTheme {
    /// 主色：橘色 #FC5200
    static let accent = Color(red: 252 / 255, green: 82 / 255, blue: 0)
    /// 主色上的柔和底（chips 選取、標籤底色）
    static let accentSoft = accent.opacity(0.18)

    /// 頁面底色 #0E0E11
    static let background = Color(red: 14 / 255, green: 14 / 255, blue: 17 / 255)
    /// 卡片、列表列 #1A1A1F
    static let surface = Color(red: 26 / 255, green: 26 / 255, blue: 31 / 255)
    /// 卡片上再疊一層（輸入框、chips 未選取、浮動按鈕）#26262D
    static let elevated = Color(red: 38 / 255, green: 38 / 255, blue: 45 / 255)
    /// 細分隔線與卡片描邊
    static let separator = Color.white.opacity(0.08)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.4)

    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let danger = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
    /// 提示類卡片（例如喝水提醒）
    static let info = Color(red: 90 / 255, green: 200 / 255, blue: 250 / 255)

    static let cardCornerRadius: CGFloat = 16
}
