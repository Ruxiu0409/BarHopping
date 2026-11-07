import SwiftUI

/// 全 App 共用的深色系配色。App 一律以深色模式呈現（ContentView 設定 preferredColorScheme(.dark)）。
/// 各分頁的 *Theme 檔請引用這裡的顏色，不要各自定義另一套底色。
enum AppTheme {
    /// 暗葡萄紫 #6B2D91：實心按鈕、選中填色與分頁列 tint；白字對比 8.72:1。
    static let accent = Color(red: 107 / 255, green: 45 / 255, blue: 145 / 255)
    /// 同色相柔紫 #B783D6：深色背景上的文字連結、小圖示與細線；頁面底對比 6.64:1。
    static let accentOnDark = Color(red: 183 / 255, green: 131 / 255, blue: 214 / 255)
    /// 柔和底：#6B2D91，18% 不透明度；疊在 background 為 #1F1428、surface 為 #291D34
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

/// 全 App 共用的深色微漸層卡片，沿用個人檔案卡片的柔紫光感。
struct AppGradientCard: ViewModifier {
    var cornerRadius: CGFloat = AppTheme.cardCornerRadius

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }

    func body(content: Content) -> some View {
        content
            .background {
                shape.fill(LinearGradient(
                    colors: [
                        AppTheme.surface,
                        AppTheme.surface.opacity(0.84),
                        AppTheme.elevated.opacity(0.8),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            }
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(AppTheme.accent.opacity(0.10))
                    .frame(width: 150, height: 150)
                    .blur(radius: 34)
                    .offset(x: 40, y: -68)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
            .overlay {
                shape.strokeBorder(AppTheme.separator, lineWidth: 1)
                .allowsHitTesting(false)
            }
            .clipShape(shape)
    }
}

extension View {
    func appGradientCard(cornerRadius: CGFloat = AppTheme.cardCornerRadius) -> some View {
        modifier(AppGradientCard(cornerRadius: cornerRadius))
    }
}
