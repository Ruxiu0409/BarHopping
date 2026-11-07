import Foundation

/// 客戶端唯一的資料來源介面（HTTP API v1，規格第 6 節）。
/// 失敗時一律 throw `ServiceError`。實作：MockBarHoppingAPI（Services/）、HTTPBarHoppingAPI（Services/）。
protocol BarHoppingAPI: Sendable {
    func config() async throws -> AppConfig
    func places(in bbox: BoundingBox, query: String?, limit: Int, cursor: String?) async throws -> PlacesPage
    func place(id: String) async throws -> Place
    func previewRoute(_ request: RouteRequest) async throws -> RouteResult
}

/// 本機草稿儲存（多份 RoutePlan，可附帶 RouteResult）。實作在 Services/。
nonisolated struct SavedDraft: Codable, Hashable, Identifiable, Sendable {
    var plan: RoutePlan
    var result: RouteResult?
    var savedAt: Date
    var id: String { plan.id }
}

protocol DraftStoring: Sendable {
    func loadAll() async throws -> [SavedDraft]   // 損壞或 schemaVersion 不支援時 throw，不得覆寫原檔
    func save(_ draft: SavedDraft) async throws
    func delete(id: String) async throws
}
