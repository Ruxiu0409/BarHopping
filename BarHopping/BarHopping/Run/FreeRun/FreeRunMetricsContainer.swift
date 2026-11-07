import SwiftUI

struct FreeRunMetricsContainer: View {
    let store: FreeRunStore
    let isExpanded: Bool
    let expand: () -> Void

    var body: some View {
        FreeRunLiveMetricsCard(session: store.session, status: gpsStatus,
                               isExpanded: isExpanded, expand: expand)
    }

    private var gpsStatus: String {
        if store.session.isPaused { return "已暫停" }
        if store.session.isDemo { return "示範模式" }
        if store.status == .denied { return "定位未授權" }
        if store.status == .unavailable { return "定位暫時不可用" }
        if store.session.hasAccurateLocation { return "GPS 已連線" }
        return store.status == .waiting ? "正在取得 GPS" : "定位精確度不足"
    }
}
