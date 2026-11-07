import SwiftUI

struct FreeRunLiveMetricsCard: View {
    let session: FreeRunSession
    let now: Date
    let status: String
    var isExpanded = false
    let expand: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Label(status, systemImage: session.isPaused ? "pause.circle.fill" : "location.circle.fill")
                    .font(.caption.bold()).foregroundStyle(AppTheme.accentOnDark)
                Spacer()
                Button(isExpanded ? "收合" : "展開", systemImage: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right", action: expand)
                    .font(.caption).foregroundStyle(AppTheme.textPrimary)
                    .frame(minWidth: 44, minHeight: 44)
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
        metric("\(session.uniqueBarCount) 家", label: "已喝", prominent: false)
            .accessibilityLabel("已喝 \(session.uniqueBarCount) 家")
            .animation(AppMotion.resolved(AppMotion.tap, reduceMotion: reduceMotion || appReduceMotion),
                       value: session.uniqueBarCount)
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
