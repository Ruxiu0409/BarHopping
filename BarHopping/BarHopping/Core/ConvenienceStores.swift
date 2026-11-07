import Foundation

// 超商點位（7-ELEVEN、全家）。與酒吧 Place 分開，不屬於 HTTP API v1 契約，
// 目前由 App 內附的 OSM 資料提供（Services/ 實作）。不得引用地圖 SDK 型別。

nonisolated enum ConvenienceBrand: String, Codable, CaseIterable, Sendable {
    case sevenEleven = "7-ELEVEN"
    case familyMart = "全家"
}

nonisolated struct ConvenienceStore: Codable, Hashable, Identifiable, Sendable {
    var id: String              // 例如 "osm-node-123456"
    var brand: ConvenienceBrand
    var name: String            // 分店名，例如「7-ELEVEN 草悟門市」；沒有分店名時用品牌名
    var coordinate: Coordinate
    var address: String?
    var openingHoursText: String?
    var source: String          // "osm"
    var sourceId: String        // 例如 "node/123456"
}

protocol ConvenienceStoreProviding: Sendable {
    /// 回傳 bbox 內的超商；brands 為空代表全部品牌。
    func stores(in bbox: BoundingBox, brands: Set<ConvenienceBrand>) async throws -> [ConvenienceStore]
}

/// 尚未接上資料時的空實作。
nonisolated struct EmptyConvenienceStoreProvider: ConvenienceStoreProviding {
    func stores(in bbox: BoundingBox, brands: Set<ConvenienceBrand>) async throws -> [ConvenienceStore] { [] }
}
