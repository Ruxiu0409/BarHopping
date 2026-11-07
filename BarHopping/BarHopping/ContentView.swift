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
                } label: {
                    tabLabel(for: tab)
                }
            }
        }
        .tint(Color(red: 252 / 255, green: 82 / 255, blue: 0))
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
