import SwiftUI

struct FreeRunSummaryView: View {
    let session: FreeRunSession
    let close: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("這次的自由路跑").font(.largeTitle.bold())
                if session.isDemo {
                    Label("示範模式紀錄", systemImage: "play.circle.fill")
                        .foregroundStyle(AppTheme.accentOnDark)
                }
                FreeRunMetricsView(session: session, now: session.endedAt ?? .now)
                if !session.samples.isEmpty || !session.visits.isEmpty {
                    FreeRunMapView(session: session, friends: [], now: session.endedAt ?? .now, isSummary: true)
                        .frame(height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                        .accessibilityLabel("這次路跑的完整軌跡與停留酒吧地圖")
                }
                Text("停留紀錄").font(.title2.bold())
                if session.visits.isEmpty {
                    Text("這次沒有記錄停留的酒吧。")
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ForEach(session.visits) { visit in
                    HStack(alignment: .top) {
                        Image(systemName: "wineglass.fill").foregroundStyle(AppTheme.accentOnDark)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(visit.name).font(.headline)
                            Text(visit.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                Text("紀錄暫存於記憶體，關閉 App 後不會保留。")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                Text("飲酒後請勿騎車開車").font(.footnote)
                SafeRideButton()
                Button("關閉", action: close)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accent)
    }
}
