import SwiftUI

struct FreeRunMetricsView: View {
    let session: FreeRunSession
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("已喝").font(.caption).foregroundStyle(AppTheme.textSecondary)
                Text("\(session.uniqueBarCount) 家")
                    .font(.largeTitle.bold()).monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(AppTheme.accentOnDark)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("已喝 \(session.uniqueBarCount) 家")
            HStack(spacing: 20) {
                metric("經過時間", Self.clock(session.elapsed(at: now)))
                metric("距離", Fmt.distance(session.distanceMeters))
            }
        }
        .padding(20)
        .appGradientCard()
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
