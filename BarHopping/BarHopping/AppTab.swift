import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case map
    case run
    case groups
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "首頁"
        case .map: "地圖"
        case .run: "路跑"
        case .groups: "團體"
        case .profile: "你"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .map: "map"
        case .run: "figure.run"
        case .groups: "person.3"
        case .profile: "person.crop.circle"
        }
    }

    var emptyStateTitle: String {
        switch self {
        case .home: "歡迎來到 BarHopping"
        case .map: "探索酒吧"
        case .run: "規劃你的路線"
        case .groups: "與朋友一起出發"
        case .profile: "你的 BarHopping"
        }
    }

    var emptyStateDescription: String {
        switch self {
        case .home: "從這裡開始下一趟酒吧散步。"
        case .map: "酒吧地圖與地點搜尋功能即將推出。"
        case .run: "站點安排與步行路線規劃功能即將推出。"
        case .groups: "團體功能即將推出。"
        case .profile: "個人設定功能即將推出。"
        }
    }
}
