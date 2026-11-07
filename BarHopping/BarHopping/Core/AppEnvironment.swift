import Foundation

/// 選擇 API 與草稿儲存的實作。後端完成前預設使用 mock。
enum AppEnvironment {
    static func makeAPI() -> BarHoppingAPI { MockBarHoppingAPI() }
    static func makeDraftStore() -> DraftStoring { InMemoryDraftStore() }
}
