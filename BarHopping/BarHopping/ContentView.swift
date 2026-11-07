import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var planner = PlannerStore(api: AppEnvironment.makeAPI(), drafts: AppEnvironment.makeDraftStore())
    /// 預留使用者大頭貼狀態：未來完成個人設定後可自訂替換
    @State private var userAvatarImage: Image? = nil

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(value: tab) {
                    switch tab {
                    case .home: HomeTabView()
                    case .map: MapTabView()
                    case .run: RunTabView()
                    case .groups: GroupsTabView()
                    default: TabLandingView(tab: tab)
                    }
                } label: {
                    if tab == .profile, let userAvatar = userAvatarImage {
                        userAvatar
                        Text(tab.title)
                    } else {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                }
            }
        }
        .tint(Color(red: 252 / 255, green: 82 / 255, blue: 0))
        .environment(router)
        .environment(planner)
    }
}

#Preview {
    ContentView()
}
