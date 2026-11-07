import Foundation

/// Curated facts and venue photography sourced from public venue and editorial pages.
/// Core Place data remains compatible with the shared API contract.
struct PlaceEditorialInfo {
    let summary: String
    let phoneNumber: String?
    let photoURL: URL?
    let photoCredit: String?
    let openingHours: String?
    let sourceTitle: String
    let sourceURL: URL
    let websiteURL: URL?
    let websiteLabel: String?

    static func forPlace(_ place: Place) -> PlaceEditorialInfo? {
        return switch place.id {
        case "osm-node-14006235445": // Vender Bar
            PlaceEditorialInfo(
                summary: "販賣機門後的 speakeasy 酒吧，以東南亞香料與風味設計創意調酒。2026 年入選 Asia’s 50 Best Bars。",
                phoneNumber: "04-2372-5875",
                photoURL: nil,
                photoCredit: nil,
                openingHours: nil,
                sourceTitle: "Top 50 Bars Asia",
                sourceURL: URL(string: "https://top50bars.asia/en/bars/vender-taichung")!,
                websiteURL: URL(string: "https://inline.app/booking/venderbar")!,
                websiteLabel: "線上訂位"
            )
        case "osm-node-10917441173": // Bar MED
            PlaceEditorialInfo(
                summary: "臺虎旗下的地中海風格餐酒館，供應手作雞尾酒、餐前酒與地中海小點。",
                phoneNumber: "04-2305-5578",
                photoURL: URL(string: "https://shoplineimg.com/67bbd9862a84000028ac9596/67eb668a61143e000a61183d/750x.webp?source_format=JPG")!,
                photoCredit: "照片：臺虎精釀官方頁面",
                openingHours: "週二–四 18:00–23:30・週五–六 12:00–02:00・週日 12:00–23:30・週一公休",
                sourceTitle: "欣傳媒・Bar MED 店家介紹",
                sourceURL: URL(string: "https://www.xinmedia.com/article/212385")!,
                websiteURL: URL(string: "https://www.taihubrewing.com/pages/taihu-retail")!,
                websiteLabel: "臺虎官方資訊"
            )
        default:
            nil
        }
    }
}
