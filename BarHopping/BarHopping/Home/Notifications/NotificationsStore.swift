import Foundation
import Observation

@MainActor @Observable
final class NotificationsStore {
    private(set) var notifications: [HomeNotification]

    init(notifications: [HomeNotification] = NotificationsMockData.make()) {
        self.notifications = notifications.sorted { $0.createdAt > $1.createdAt }
    }

    var unreadCount: Int { notifications.filter { !$0.isRead }.count }

    func markRead(_ id: HomeNotification.ID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = true
    }

    func markAllRead() {
        for index in notifications.indices { notifications[index].isRead = true }
    }

    func notifications(in section: NotificationsSection, now: Date = .now, calendar: Calendar = .current) -> [HomeNotification] {
        notifications.filter { notification in
            if calendar.isDate(notification.createdAt, inSameDayAs: now) { return section == .today }
            let isThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.contains(notification.createdAt) == true
            return section == (isThisWeek ? .thisWeek : .earlier)
        }
    }
}
