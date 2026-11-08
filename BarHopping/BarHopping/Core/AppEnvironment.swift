import Foundation

/// 選擇 API 與草稿儲存的實作。
/// 預設使用 mock；環境變數或 Info.plist 的 `BARHOPPING_API_BASE_URL` 有值時改用 HTTP API。
enum AppEnvironment {
    static let apiBaseURLKey = "BARHOPPING_API_BASE_URL"
    static let googlePlacesAPIKeyKey = "GOOGLE_PLACES_API_KEY"

    static func makeAPI() -> BarHoppingAPI {
        if let baseURL = apiBaseURL { return HTTPBarHoppingAPI(baseURL: baseURL) }
        return MockBarHoppingAPI()
    }

    static func makeDraftStore() -> DraftStoring { FileDraftStore() }

    /// 地圖使用 App 內附的 OSM 超商資料。
    static func makeConvenienceStoreProvider() -> ConvenienceStoreProviding { BundledConvenienceStoreProvider() }

    static func makePopularRouteProvider() -> PopularRouteProviding { BundledPopularRouteProvider() }

    /// 環境變數優先於 Info.plist；只接受 http(s) 網址。
    static var apiBaseURL: URL? {
        let candidates = [
            ProcessInfo.processInfo.environment[apiBaseURLKey],
            Bundle.main.object(forInfoDictionaryKey: apiBaseURLKey) as? String,
        ]
        for raw in candidates.compactMap({ $0?.trimmingCharacters(in: .whitespacesAndNewlines) }) where !raw.isEmpty {
            if let url = URL(string: raw), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host() != nil {
                return url
            }
        }
        return nil
    }

    /// 金鑰在編譯時從本機 xcconfig 寫入 Info.plist，絕不放進版本控制。
    static var googlePlacesAPIKey: String? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: googlePlacesAPIKeyKey) as? String else { return nil }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !key.contains("$(") else { return nil }
        return key
    }
}
