import SwiftUI
import UIKit

/// 地圖分頁配色與共用小元件。
enum MapTheme {
    static let accent = AppTheme.accent
    static let accentOnDark = AppTheme.accentOnDark
    static let surface = AppTheme.surface
    static let elevated = AppTheme.elevated
    static let textPrimary = AppTheme.textPrimary
    static let textSecondary = AppTheme.textSecondary
    static let separator = AppTheme.separator

    static let uiAccent = UIColor(AppTheme.accent)
    static let uiLabel = UIColor(AppTheme.textPrimary)
    static let uiHalo = UIColor(AppTheme.background)
    static let uiOrigin = UIColor(AppTheme.success)
    static let uiDestination = UIColor(AppTheme.info)
    static let uiSevenEleven = UIColor(red: 0.08, green: 0.45, blue: 0.30, alpha: 1)
    static let uiFamilyMart = UIColor(red: 0.08, green: 0.37, blue: 0.64, alpha: 1)

    static let origin = AppTheme.success
    static let destination = AppTheme.info

    static func categoryText(_ c: PlaceCategory) -> String {
        switch c {
        case .bar: "酒吧"
        case .pub: "Pub（酒館）"
        }
    }
}

/// 深色圓形浮動按鈕。
struct MapRoundButtonLabel: View {
    var systemImage: String
    var active = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(MapTheme.textPrimary)
            .frame(width: 46, height: 46)
            .background(active ? MapTheme.accent : MapTheme.elevated, in: Circle())
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}

/// 深色圓角浮動卡片外框。
struct MapCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(MapTheme.textPrimary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MapTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }
}

extension View {
    func mapCard() -> some View { modifier(MapCardModifier()) }
}
