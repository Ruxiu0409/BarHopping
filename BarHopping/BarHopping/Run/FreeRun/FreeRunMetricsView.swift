import SwiftUI

struct FreeRunMetricsView: View {
    let session: FreeRunSession
    let now: Date

    var body: some View {
        let elapsed = session.elapsed(at: now)
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            metric("經過時間", Self.clock(elapsed))
            metric("距離", Fmt.distance(session.distanceMeters))
            metric("平均速度", String(format: "%.1f km/h", elapsed > 0 ? session.distanceMeters / elapsed * 3.6 : 0))
            metric("已停留酒吧", "\(session.uniqueBarCount) 間")
        }
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(AppTheme.textSecondary)
            Text(value).font(.title3.bold()).monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    static func clock(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        return String(format: "%02d:%02d:%02d", total / 3600, total / 60 % 60, total % 60)
    }
}
