import SwiftUI
import UIKit

/// 地圖分頁配色與共用小元件。
enum MapTheme {
    static let uiAccent = UIColor(red: 0xFC / 255, green: 0x52 / 255, blue: 0, alpha: 1)
    static let uiAccentDark = UIColor(red: 0xB8 / 255, green: 0x3A / 255, blue: 0, alpha: 1)
    static let uiOrigin = UIColor(red: 0.13, green: 0.6, blue: 0.33, alpha: 1)
    static let uiDestination = UIColor(white: 0.15, alpha: 1)

    static let accent = Color(uiColor: uiAccent)
    static let origin = Color(uiColor: uiOrigin)
    static let destination = Color(uiColor: uiDestination)

    static func categoryText(_ c: PlaceCategory) -> String {
        switch c {
        case .bar: "酒吧"
        case .pub: "Pub（酒館）"
        }
    }
}

/// 白底圓形浮動按鈕。
struct MapRoundButtonLabel: View {
    var systemImage: String
    var active = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(active ? MapTheme.accent : Color.primary)
            .frame(width: 46, height: 46)
            .background(.background, in: Circle())
            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
    }
}

/// 白底圓角浮動卡片外框。
struct MapCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
    }
}

extension View {
    func mapCard() -> some View { modifier(MapCardModifier()) }
}
