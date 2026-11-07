import SwiftUI

struct RunTabView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showRun = false
    @State private var demoMode = false
    @State private var latestRun: FreeRunSession?
    @State private var showDrinkPass = false
    @State private var drinkPassPurchases: [DrinkPassPurchase] = []
    @State private var runningStore: FreeRunStore?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    RunStartButton {
                        if runningStore == nil {
                            let store = FreeRunStore(isDemo: demoMode)
                            runningStore = store
                            store.start()
                        }
                        showRun = true
                    }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    introduction
                    if let latestRun {
                        FreeRunLatestCard(session: latestRun)
                    }
                    DrinkPassBanner(event: DrinkPassMockData.event) { showDrinkPass = true }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background)
            .foregroundStyle(AppTheme.textPrimary)
            .navigationTitle("路跑")
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                if let store = runningStore, !showRun {
                    Button { showRun = true } label: {
                        HStack {
                            Image(systemName: store.session.isPaused ? "pause.circle.fill" : "figure.walk")
                            VStack(alignment: .leading) {
                                Text(store.session.isPaused ? "路跑已暫停" : "路跑進行中").font(.headline)
                                Text("\(FreeRunMetricsView.clock(store.session.elapsed(at: store.now))) · \(Fmt.distance(store.session.distanceMeters))")
                                    .font(.caption).monospacedDigit()
                            }
                            Spacer()
                            Text("返回路跑").font(.subheadline)
                        }
                        .padding(14).appGradientCard(cornerRadius: 16)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 8)
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .navigationDestination(isPresented: $showDrinkPass) {
                DrinkPassDetailView(event: DrinkPassMockData.event, purchases: $drinkPassPurchases)
            }
            .fullScreenCover(isPresented: $showRun) {
                if let store = runningStore {
                    FreeRunView(store: store, onCollapse: { showRun = false }) { session in
                        latestRun = session
                        showRun = false
                        runningStore = nil
                    }
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { runningStore?.start() } else { runningStore?.suspend() }
        }
    }

    private var introduction: some View {
        VStack(spacing: 12) {
            Text("想走到哪，就走到哪").font(.title3.bold())
            Text("按下開始，自由步行。靠近酒吧時按「買酒」，留下停留紀錄。")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Toggle("示範模式", isOn: $demoMode)
                .padding(16)
                .appGradientCard()
            Text(demoMode ? "不用出門，以審計新村假定位體驗路跑。" : "使用真實定位，僅在 App 前景時更新。")
                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
        }
    }

}

#Preview {
    RunTabView()
}
