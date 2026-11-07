import SwiftUI

/// 站點清單的一列：編號、店名、停留時間、上移／下移、刪除。
struct RunStopRow: View {
    let stop: Stop
    let index: Int
    let count: Int
    let isProblem: Bool
    let onDwell: (Int) -> Void
    let onMove: (Int) -> Void
    let onDelete: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private static let dwellStep = 5

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(index + 1)")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(minWidth: 28, minHeight: 28)
                    .background(Circle().fill(isProblem ? Color.red : RunTheme.accent))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(stop.waypoint.name)
                            .font(.headline)
                            .foregroundStyle(isProblem ? .red : .primary)
                        if stop.waypoint.placeId == nil {
                            Text("自訂")
                                .font(.caption.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .foregroundStyle(RunTheme.accent)
                                .background(Capsule().strokeBorder(RunTheme.accent))
                        }
                    }
                    if isProblem {
                        Label("找不到可步行的道路", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityTitle)

            Stepper(value: Binding(get: { stop.dwellMinutes }, set: onDwell),
                    in: Stop.dwellRange, step: Self.dwellStep) {
                Label("停留 \(Fmt.minutes(stop.dwellMinutes))", systemImage: "clock")
                    .font(.subheadline)
            }
            .accessibilityLabel("第 \(index + 1) 站 \(stop.waypoint.name) 停留時間")
            .accessibilityValue(Fmt.minutes(stop.dwellMinutes))

            HStack(spacing: 8) {
                Button { onMove(-1) } label: {
                    Label("上移", systemImage: "arrow.up")
                }
                .tint(RunTheme.accent)
                .disabled(index == 0)
                .accessibilityLabel("將 \(stop.waypoint.name) 上移")

                Button { onMove(1) } label: {
                    Label("下移", systemImage: "arrow.down")
                }
                .tint(RunTheme.accent)
                .disabled(index == count - 1)
                .accessibilityLabel("將 \(stop.waypoint.name) 下移")

                Spacer(minLength: 0)

                Button(role: .destructive, action: onDelete) {
                    Label("刪除", systemImage: "trash")
                }
                .tint(.red)
                .accessibilityLabel("刪除 \(stop.waypoint.name)")
            }
            .font(.subheadline)
            // 輔助字級下只顯示圖示，避免小螢幕擠爆；VoiceOver 仍讀 accessibilityLabel。
            .labelStyle(AnyLabelStyle(iconOnly: typeSize.isAccessibilitySize))
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
    }

    private var accessibilityTitle: String {
        var s = "第 \(index + 1) 站，\(stop.waypoint.name)"
        if stop.waypoint.placeId == nil { s += "，自訂站點" }
        if isProblem { s += "，找不到可步行的道路" }
        return s
    }
}

private struct AnyLabelStyle: LabelStyle {
    let iconOnly: Bool
    func makeBody(configuration: Configuration) -> some View {
        if iconOnly {
            configuration.icon
        } else {
            HStack(spacing: 4) { configuration.icon; configuration.title }
        }
    }
}
