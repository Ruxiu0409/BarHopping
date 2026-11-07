import SwiftUI

/// 路跑分頁的配色與錯誤說明。
enum RunTheme {
    /// 主色 #FC5200
    static let accent = AppTheme.accent
}

extension ServiceError {
    /// 給使用者看的錯誤標題（依錯誤碼）。
    var runTitle: String {
        switch code {
        case .invalidRequest: "路線資料有誤"
        case .outsideServiceArea: "超出服務範圍"
        case .noWalkableRoute: "找不到可步行的路線"
        case .placeNotFound: "找不到店家"
        case .rateLimited: "請求太頻繁"
        case .upstreamUnavailable: "路線服務暫時無法使用"
        case .upstreamTimeout: "路線服務回應逾時"
        case .clientNetwork: "無法連線"
        }
    }

    /// 白話說明與建議的下一步。
    var runExplanation: String {
        switch code {
        case .invalidRequest:
            "請檢查起點、站點與終點設定後再計算一次。"
        case .outsideServiceArea:
            "有站點不在目前支援的區域內，請到地圖改選服務範圍內的地點。"
        case .noWalkableRoute:
            "標示為紅色的站點離可步行的道路太遠（超過 100 公尺），或附近沒有可通行的步道。請在地圖上移動或刪除這些站點後再試。"
        case .placeNotFound:
            "有店家資料已不存在，請刪除該站或改選其他酒吧。"
        case .rateLimited:
            "短時間內計算太多次了，請稍等一下再按「重試」。"
        case .upstreamUnavailable:
            "路線服務目前忙碌或維護中，請稍後按「重試」。"
        case .upstreamTimeout:
            "路線服務太久沒有回應，請按「重試」。"
        case .clientNetwork:
            "請確認網路連線後按「重試」。"
        }
    }

    /// 是否顯示「重試」按鈕：retryable 錯誤，以及 NO_WALKABLE_ROUTE（修正站點後重試）。
    var runShowsRetry: Bool { retryable || code == .noWalkableRoute }
}
