import Foundation

/// 依共用規格範例運作的 mock（由 Services agent 實作完整資料）。
nonisolated struct MockBarHoppingAPI: BarHoppingAPI {
    func config() async throws -> AppConfig { throw Self.todo }
    func places(in bbox: BoundingBox, query: String?, limit: Int, cursor: String?) async throws -> PlacesPage { PlacesPage(items: [], nextCursor: nil) }
    func place(id: String) async throws -> Place { throw Self.todo }
    func previewRoute(_ request: RouteRequest) async throws -> RouteResult { throw Self.todo }
    static let todo = ServiceError(clientRequestId: nil, code: .upstreamUnavailable, message: "尚未實作", retryable: true, waypointIds: [])
}

nonisolated struct InMemoryDraftStore: DraftStoring {
    func loadAll() async throws -> [SavedDraft] { [] }
    func save(_ draft: SavedDraft) async throws {}
    func delete(id: String) async throws {}
}
