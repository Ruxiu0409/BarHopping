import Foundation

struct SafeRideProvider: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case designatedDriver = "代駕"
        case taxi = "計程車"

        var id: Self { self }
    }

    enum OpeningMethod {
        case uberUniversalLink
        case appStore(id: String)
        case phone(number: String)

        var label: String {
            switch self {
            case .uberUniversalLink: "開啟 App／網頁"
            case .appStore: "前往 App Store"
            case .phone: "電話叫車"
            }
        }
    }

    let id: String
    let name: String
    let kind: Kind
    let summary: String
    let symbol: String
    let openingMethod: OpeningMethod

    // 以台灣區 iTunes Search 與 Lookup API 核對乘客端 App，2026-11-07。
    static let all: [SafeRideProvider] = [
        .init(id: "twdd", name: "台灣代駕 TWDD", kind: .designatedDriver,
              summary: "由代駕駕駛協助您與愛車返家", symbol: "steeringwheel",
              openingMethod: .appStore(id: "1003660128")),
        .init(id: "uber", name: "Uber 優步", kind: .taxi,
              summary: "帶入上車地點，於服務內確認行程", symbol: "car.side.fill",
              openingMethod: .uberUniversalLink),
        .init(id: "55688-app", name: "55688 台灣大車隊", kind: .taxi,
              summary: "開啟商店頁後，打開或下載乘客 App", symbol: "car.fill",
              openingMethod: .appStore(id: "579255069")),
        .init(id: "line-go", name: "LINE GO", kind: .taxi,
              summary: "透過 LINE GO 選擇計程車行程", symbol: "bubble.left.and.bubble.right.fill",
              openingMethod: .appStore(id: "1538897906")),
        .init(id: "yoxi", name: "yoxi", kind: .taxi,
              summary: "開啟商店頁後，打開或下載乘客 App", symbol: "car.side.fill",
              openingMethod: .appStore(id: "1521393667")),
        .init(id: "55688-phone", name: "撥打 55688", kind: .taxi,
              summary: "手機電話叫車，通話費依電信方案計算", symbol: "phone.fill",
              openingMethod: .phone(number: "55688"))
    ]
}
