import Foundation

enum GroupDrinkLevel: String, CaseIterable, Identifiable {
    case alcoholFree, light, tipsy, social

    var id: Self { self }

    var title: String {
        switch self {
        case .alcoholFree: "不喝也來"
        case .light: "小酌"
        case .tipsy: "微醺"
        case .social: "暢飲"
        }
    }

    var symbol: String {
        switch self {
        case .alcoholFree: "cup.and.saucer.fill"
        case .light: "wineglass"
        case .tipsy: "wineglass.fill"
        case .social: "mug.fill"
        }
    }

    var description: String {
        switch self {
        case .alcoholFree: "無酒精也開心，聊天散步都歡迎。"
        case .light: "一兩杯慢慢品味，輕鬆聊聊。"
        case .tipsy: "享受微醺氣氛，依自己的步調。"
        case .social: "一起品味不同風味，不勸酒、不拚杯。"
        }
    }

    var reminder: String? {
        self == .social ? "量力而為，喝酒不開車" : nil
    }
}
