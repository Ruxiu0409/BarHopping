import SwiftUI

struct ContentView: View {
    @State private var router = AppRouter()
    @State private var planner = PlannerStore(api: AppEnvironment.makeAPI(), drafts: AppEnvironment.makeDraftStore())

    var body: some View {
        TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    switch tab {
                    case .home: HomeTabView()
                    case .map: MapTabView()
                    case .run: RunTabView()
                    default: TabLandingView(tab: tab)
                    }
                }
            }
        }
        .environment(router)
        .environment(planner)
    }
}

#Preview {
    ContentView()
}
