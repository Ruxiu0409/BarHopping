import Foundation

/// 首頁個人區塊的假資料（之後換成帳號與紀錄 API）。
struct HomeUser: Sendable {
    var nickname: String
    var initials: String
    var colorIndex: Int
    var level: String

    var forumAuthor: ForumAuthor { ForumAuthor(name: nickname, initials: initials, colorIndex: colorIndex) }
}

struct HomeStats: Sendable {
    var monthWalkedMeters: Double
    var barsVisited: Int
    var routesCompleted: Int
    var districtsExplored: Int
}

enum HomeMockProfile {
    static let user = HomeUser(nickname: "小酌", initials: "酌", colorIndex: 0, level: "城市漫步者 Lv.3")

    static let stats = HomeStats(monthWalkedMeters: 23_400, barsVisited: 9, routesCompleted: 3, districtsExplored: 5)

}
