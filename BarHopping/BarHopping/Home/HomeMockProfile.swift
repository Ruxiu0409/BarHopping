import Foundation

/// 首頁個人區塊的假資料（之後換成帳號與紀錄 API）。
struct HomeUser: Sendable {
    var nickname: String
    var initials: String
    var colorIndex: Int
    var level: String

    var forumAuthor: ForumAuthor { ForumAuthor(name: nickname, initials: initials, colorIndex: colorIndex) }
}

struct HomeQuest: Identifiable, Sendable {
    enum Unit: Sendable { case count, meters }
    enum Kind: Sendable {
        case weekly, challenge
        var title: String { self == .weekly ? "每週任務" : "探索挑戰" }
    }

    var id: String
    var kind: Kind
    var title: String
    var detail: String
    var systemImage: String
    var progress: Double
    var goal: Double
    var unit: Unit
    var reward: String

    var fraction: Double { goal > 0 ? min(progress / goal, 1) : 0 }
    var isCompleted: Bool { progress >= goal }

    var progressText: String {
        switch unit {
        case .count: "\(Int(progress)) / \(Int(goal))"
        case .meters: "\(Fmt.distance(progress)) / \(Fmt.distance(goal))"
        }
    }
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

    static let quests: [HomeQuest] = [
        HomeQuest(id: "walk", kind: .weekly, title: "城市漫步", detail: "這週累積步行 8 公里",
                  systemImage: "figure.walk", progress: 5_200, goal: 8_000, unit: .meters, reward: "漫步者"),
        HomeQuest(id: "district", kind: .weekly, title: "新區探險", detail: "到 2 個沒去過的區走走，例如中區舊城、南屯",
                  systemImage: "map", progress: 1, goal: 2, unit: .count, reward: "探險家"),
        HomeQuest(id: "variety", kind: .challenge, title: "風格收集", detail: "試試 3 種不同風格的店：精釀、爵士、黑膠",
                  systemImage: "square.grid.3x3", progress: 2, goal: 3, unit: .count, reward: "品味家"),
        HomeQuest(id: "friends", kind: .challenge, title: "揪朋友出門", detail: "和朋友一起完成一條路線",
                  systemImage: "person.2", progress: 0, goal: 1, unit: .count, reward: "好夥伴"),
        HomeQuest(id: "route", kind: .weekly, title: "完整走完", detail: "完成一條 3 站以上的路線",
                  systemImage: "flag.checkered", progress: 1, goal: 1, unit: .count, reward: "完走"),
    ]

    static let safetyTip = "每站之間喝一杯水，出門前先想好怎麼回家。有喝就不騎車、不開車，最後一站排在大路或公車站附近，叫車回家會輕鬆很多。"
}
