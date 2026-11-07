import SwiftUI

struct NotificationRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let notification: HomeNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notification.symbol)
                .font(.title3)
                .foregroundStyle(HomeTheme.accentOnDark)
                .frame(width: 36, height: 36)
                .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(notification.title)
                        .font(.headline)
                    if !notification.isRead {
                        Circle().fill(HomeTheme.accentOnDark).frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                Text(notification.message)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    Text(HomeTheme.relative(notification.createdAt, now: context.date))
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityValue(notification.isRead ? "已讀" : "未讀")
    }
}
