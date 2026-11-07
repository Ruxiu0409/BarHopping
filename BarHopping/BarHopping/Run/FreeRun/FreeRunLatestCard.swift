import SwiftUI

struct FreeRunLatestCard: View {
    let session: FreeRunSession

    private var summary: String {
        let elapsed: String = FreeRunMetricsView.clock(session.elapsed(at: .now))
        let distance: String = Fmt.distance(session.distanceMeters)
        return "\(elapsed) · \(distance)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.isDemo ? "最近一次 · 示範模式" : "最近一次路跑")
                .font(.headline)
            Text("已喝 \(session.uniqueBarCount) 家")
                .font(.title2.bold()).monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(AppTheme.accentOnDark)
                .accessibilityLabel("已喝 \(session.uniqueBarCount) 家")
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appGradientCard()
    }
}
