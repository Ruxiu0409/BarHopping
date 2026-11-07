import SwiftUI

struct FreeRunLiveMetricsCard: View {
    let session: FreeRunSession
    let now: Date
    let status: String
    let expand: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(status, systemImage: session.isPaused ? "pause.circle.fill" : "location.circle.fill")
                    .font(.caption.bold()).foregroundStyle(AppTheme.accentOnDark)
                Spacer()
                Button("展開", systemImage: "arrow.up.left.and.arrow.down.right", action: expand)
                    .font(.caption).foregroundStyle(AppTheme.textPrimary)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 16) { metrics }
                VStack(spacing: 12) { metrics }
            }
        }
        .padding(16)
        .appGradientCard(cornerRadius: 20)
    }

    @ViewBuilder private var metrics: some View {
        metric(FreeRunMetricsView.clock(session.elapsed(at: now)), label: "時間", prominent: false)
        metric(String(format: "%.2f", session.distanceMeters / 1_000), label: "距離（公里）", prominent: true)
        let elapsed = session.elapsed(at: now)
        metric(String(format: "%.1f", elapsed > 0 ? session.distanceMeters / elapsed * 3.6 : 0),
               label: "平均公里／小時", prominent: false)
    }

    private func metric(_ value: String, label: String, prominent: Bool) -> some View {
        VStack(spacing: 4) {
            Text(value).font(prominent ? .largeTitle.bold() : .title3.bold())
                .monospacedDigit().contentTransition(.numericText())
                .fixedSize(horizontal: true, vertical: false)
            Text(label).font(.caption2).foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
