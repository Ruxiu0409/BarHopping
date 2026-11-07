import Observation

/// 分頁切換（例如路跑的「在地圖查看」）。
@MainActor @Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    /// 切換到地圖時要求地圖把目前路線完整框進畫面。
    var mapFocusRouteRequest = 0

    func showRouteOnMap() {
        mapFocusRouteRequest += 1
        selectedTab = .map
    }
}
