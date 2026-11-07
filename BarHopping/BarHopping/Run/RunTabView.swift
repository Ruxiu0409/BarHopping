import SwiftUI

struct RunTabView: View {
    @State private var showRun = false
    @State private var demoMode = false
    @State private var latestRun: FreeRunSession?
    @State private var showDrinkPass = false
    @State private var drinkPassPurchases: [DrinkPassPurchase] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    RunStartButton { showRun = true }
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
            .navigationDestination(isPresented: $showDrinkPass) {
                DrinkPassDetailView(event: DrinkPassMockData.event, purchases: $drinkPassPurchases)
            }
            .fullScreenCover(isPresented: $showRun) {
                FreeRunView(isDemo: demoMode) { session in
                    latestRun = session
                    showRun = false
                }
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
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
                .appGlassCard()
            Text(demoMode ? "不用出門，以審計新村假定位體驗路跑。" : "使用真實定位，僅在 App 前景時更新。")
                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
        }
    }

}

#Preview {
    RunTabView()
}
