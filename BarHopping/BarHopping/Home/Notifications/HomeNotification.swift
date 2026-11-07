import Foundation

struct HomeNotification: Identifiable {
    let id: String
    let symbol: String
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool
}
