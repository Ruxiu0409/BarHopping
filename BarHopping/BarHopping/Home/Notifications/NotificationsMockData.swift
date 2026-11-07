import Foundation

enum NotificationsMockData {
    static func make(now: Date = .now, calendar: Calendar = .current) -> [HomeNotification] {
        let today = calendar.startOfDay(for: now)
        let elapsedToday = now.timeIntervalSince(today)
        func minutesAgo(_ minutes: Double) -> Date {
            now.addingTimeInterval(-min(minutes * 60, elapsedToday * 0.8))
        }
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: now)!
        }
        return [
            HomeNotification(id: "group", symbol: "person.3.fill", title: "今晚一起出發", message: "週五審計新村微醺線，19:30 在入口集合。", createdAt: minutesAgo(5), isRead: false),
            HomeNotification(id: "reply", symbol: "bubble.left.and.bubble.right.fill", title: "有人回覆你的貼文", message: "小宇回覆：這間的無酒精特調也很推薦！", createdAt: minutesAgo(20), isRead: false),
            HomeNotification(id: "tickets", symbol: "ticket.fill", title: "酒精路跑早鳥票提醒", message: "龍蛇酒雜 LONG SER 9 ZA 酒精路跑，記得留意早鳥票資訊。", createdAt: minutesAgo(60), isRead: false),
            HomeNotification(id: "water", symbol: "drop.fill", title: "喝口水，休息一下", message: "走完一站，補充水分再決定下一站吧。", createdAt: daysAgo(1), isRead: true),
            HomeNotification(id: "like", symbol: "heart.fill", title: "你的分享獲得按讚", message: "阿晴喜歡你的「台中巷弄酒吧口袋名單」。", createdAt: daysAgo(2), isRead: true),
            HomeNotification(id: "draft", symbol: "map.fill", title: "路線草稿等你完成", message: "「草悟道散步串店」已儲存，出發前記得重新計算路線。", createdAt: daysAgo(3), isRead: true),
            HomeNotification(id: "completed", symbol: "checkmark.circle.fill", title: "這次路跑完成了", message: "你完成了 3 間酒吧的步行串店，謝謝一起探索台中。", createdAt: daysAgo(9), isRead: true),
            HomeNotification(id: "safe-ride", symbol: "car.fill", title: "回家交通先安排", message: "飲酒後不開車、不騎車，搭車或找代駕平安回家。", createdAt: daysAgo(12), isRead: true),
            HomeNotification(id: "group-next", symbol: "calendar", title: "下次聚會有新提案", message: "同行夥伴提議下次走勤美周邊，歡迎一起討論。", createdAt: daysAgo(16), isRead: true),
        ]
    }
}
