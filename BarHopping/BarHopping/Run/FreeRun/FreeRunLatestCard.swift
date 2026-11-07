import SwiftUI

struct FreeRunLatestCard: View {
    let session: FreeRunSession

    private var summary: String {
        let elapsed: String = FreeRunMetricsView.clock(session.elapsed(at: .now))
        let distance: String = Fmt.distance(session.distanceMeters)
        return "\(elapsed) · \(distance) · \(session.uniqueBarCount) 間酒吧"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.isDemo ? "最近一次 · 示範模式" : "最近一次路跑")
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appGradientCard()
    }
}
