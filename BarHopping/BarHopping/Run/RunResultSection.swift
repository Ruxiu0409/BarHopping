import SwiftUI

/// 路線結果：分段、各站停留、總計與提醒。數字一律來自 RouteResult，只做顯示換算。
struct RunResultSection: View {
    let result: RouteResult
    let plan: RoutePlan
    let isDimmed: Bool

    var body: some View {
        Section {
            ForEach(Array(result.legs.enumerated()), id: \.offset) { i, leg in
                legRow(index: i, leg: leg)
            }
        } header: {
            Text("分段")
        }
        .opacity(isDimmed ? 0.45 : 1)

        Section("總計") {
            totalRow("總距離", Fmt.distance(result.distanceMeters), "figure.walk")
            totalRow("步行時間", Fmt.duration(result.walkingDurationSeconds), "shoeprints.fill")
            totalRow("停留時間", Fmt.duration(result.dwellDurationSeconds), "wineglass")
            totalRow("總時間", Fmt.duration(result.totalDurationSeconds), "clock.fill", emphasized: true)
        }
        .opacity(isDimmed ? 0.45 : 1)

        if !result.warnings.isEmpty {
            Section("提醒") {
                ForEach(result.warnings, id: \.self) { w in
                    Label(w, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private func legRow(index: Int, leg: RouteLeg) -> some View {
        let from = name(for: leg.fromWaypointId)
        let to = name(for: leg.toWaypointId)
        let dwell = dwellAfter(legIndex: index, toId: leg.toWaypointId)
        return VStack(alignment: .leading, spacing: 4) {
            Text("\(from) → \(to)")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 12) {
                Label(Fmt.distance(leg.distanceMeters), systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                Label(Fmt.duration(leg.walkingDurationSeconds), systemImage: "figure.walk")
            }
            .font(.footnote)
            .foregroundStyle(AppTheme.textSecondary)
            if let dwell {
                Label("在 \(to) 停留 \(Fmt.minutes(dwell))", systemImage: "wineglass")
                    .font(.footnote)
                    .foregroundStyle(RunTheme.accentOnDark)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "第 \(index + 1) 段，從 \(from) 到 \(to)，\(Fmt.distance(leg.distanceMeters))，步行 \(Fmt.duration(leg.walkingDurationSeconds))"
                + (dwell.map { "，停留 \(Fmt.minutes($0))" } ?? "")
        )
    }

    private func totalRow(_ title: String, _ value: String, _ icon: String, emphasized: Bool = false) -> some View {
        LabeledContent {
            Text(value)
                .font(emphasized ? .headline : .body)
                .foregroundStyle(emphasized ? RunTheme.accentOnDark : AppTheme.textPrimary)
        } label: {
            Label(title, systemImage: icon)
        }
    }

    /// 段落端點名稱：起點、終點或「n. 店名」。站點已被移除時（結果過期）顯示「已移除的站點」。
    private func name(for id: String) -> String {
        if let i = plan.stops.firstIndex(where: { $0.id == id }) {
            return "\(i + 1). \(plan.stops[i].waypoint.name)"
        }
        if let o = plan.origin, o.id == id { return "起點（\(o.name)）" }
        if let d = plan.destination, d.id == id { return "終點（\(d.name)）" }
        return "已移除的站點"
    }

    /// 抵達酒吧後的停留時間（取自規劃中的設定，總停留以 RouteResult 為準）。
    private func dwellAfter(legIndex: Int, toId: String) -> Int? {
        guard legIndex < result.legs.count - 1 else { return nil }
        return plan.stops.first(where: { $0.id == toId })?.dwellMinutes
    }
}
