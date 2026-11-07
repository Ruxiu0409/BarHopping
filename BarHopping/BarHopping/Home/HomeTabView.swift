import SwiftUI

/// 首頁分頁根畫面（由首頁代理實作）。
struct HomeTabView: View {
    var body: some View {
        ContentUnavailableView("首頁", systemImage: "house")
    }
}
