import SwiftUI

struct NotificationsView: View {
    let store: NotificationsStore

    var body: some View {
        Group {
            if store.notifications.isEmpty {
                ContentUnavailableView("目前沒有通知", systemImage: "bell.slash", description: Text("新的活動與互動提醒會出現在這裡。"))
            } else {
                List {
                    Section {
                        Text("示意通知・已讀狀態僅保留於本次使用期間。")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    ForEach(NotificationsSection.allCases) { section in
                        let items = store.notifications(in: section)
                        if !items.isEmpty {
                            Section(section.rawValue) {
                                ForEach(items) { notification in
                                    Button { store.markRead(notification.id) } label: {
                                        NotificationRow(notification: notification)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(AppTheme.surface)
                                    .accessibilityHint(notification.isRead ? "已讀" : "點兩下標為已讀")
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .navigationTitle("通知")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("全部標為已讀") { store.markAllRead() }
                    .disabled(store.unreadCount == 0)
            }
        }
        .tint(HomeTheme.accentOnDark)
    }
}

#Preview("空通知") {
    NavigationStack { NotificationsView(store: NotificationsStore(notifications: [])) }
        .preferredColorScheme(.dark)
}
