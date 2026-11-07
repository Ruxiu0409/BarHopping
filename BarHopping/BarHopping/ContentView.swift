import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var planner = PlannerStore(api: AppEnvironment.makeAPI(), drafts: AppEnvironment.makeDraftStore())
    @State private var userProfile = UserProfileStore()

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(value: tab) {
                    tabContent(for: tab)
                        .toolbarBackground(AppTheme.background, for: .tabBar)
                        .toolbarBackgroundVisibility(.visible, for: .tabBar)
                } label: {
                    tabLabel(for: tab)
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .environment(router)
        .environment(planner)
        .environment(userProfile)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeTabView()
        case .map: MapTabView()
        case .run: RunTabView()
        case .groups: GroupsTabView()
        case .profile: ProfileTabView()
        }
    }

    @ViewBuilder
    private func tabLabel(for tab: AppTab) -> some View {
        if tab == .profile, let userAvatar = userProfile.customAvatarImage {
            userAvatar
            Text(tab.title)
        } else if tab == .profile {
            // 沒選預設圖示時，用使用者大頭貼當作「你」分頁的圖示。
            Image(uiImage: UserAvatarIcon.tabImage())
            Text(tab.title)
        } else {
            Label(tab.title, systemImage: tab.systemImage)
        }
    }
}

#Preview {
    ContentView()
}
