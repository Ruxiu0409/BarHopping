import SwiftUI

/// 首頁配色與共用格式。
enum HomeTheme {
    /// 主色 #FC5200
    static let accent = AppTheme.accent
    static let cardBackground = AppTheme.surface
    static let pageBackground = AppTheme.background
    static let cornerRadius = AppTheme.cardCornerRadius

    /// 頭像底色（依作者索引輪替）。
    static let avatarColors: [Color] = [
        accent, .teal, .indigo, .pink, .green, .purple, .brown, .blue,
    ]

    /// 「3 小時前」這類相對時間。
    static func relative(_ date: Date, now: Date = .now) -> String {
        if now.timeIntervalSince(date) < 60 { return "剛剛" }
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_Hant_TW")
        f.unitsStyle = .full
        return f.localizedString(for: date, relativeTo: now)
    }
}

/// 深色圓角卡片。
struct HomeCard: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HomeTheme.cardBackground, in: .rect(cornerRadius: HomeTheme.cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: HomeTheme.cornerRadius)
                    .strokeBorder(AppTheme.separator)
            }
    }
}

extension View {
    func homeCard(padding: CGFloat = 16) -> some View { modifier(HomeCard(padding: padding)) }
}

/// 縮寫圓圈頭像。
struct InitialsAvatar: View {
    let initials: String
    let colorIndex: Int
    var size: CGFloat = 40

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: size, height: size)
            .background(HomeTheme.avatarColors[colorIndex % HomeTheme.avatarColors.count].opacity(0.7), in: .circle)
            .overlay { Circle().strokeBorder(AppTheme.separator) }
            .accessibilityHidden(true)
    }
}

/// 膠囊 chip。
struct HomeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? HomeTheme.accent : AppTheme.textPrimary)
                .background(
                    Capsule().fill(isSelected ? AppTheme.accentSoft : AppTheme.elevated)
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? HomeTheme.accent : AppTheme.separator, lineWidth: isSelected ? 1.5 : 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
