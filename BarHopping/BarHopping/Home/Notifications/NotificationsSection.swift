import Foundation

enum NotificationsSection: String, CaseIterable, Identifiable {
    case today = "今天"
    case thisWeek = "本週"
    case earlier = "更早"

    var id: Self { self }
}
