import SwiftUI

// MARK: - 店家資訊卡

struct PlaceCard: View {
    var place: Place
    var inRoute: Bool
    var onAdd: () -> Void
    var onSetOrigin: () -> Void
    var onSetDestination: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text(MapTheme.categoryText(place.category))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MapTheme.accentOnDark)
                }
                Spacer(minLength: 8)
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(MapTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(MapTheme.elevated, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("關閉")
            }
            infoRow("mappin.and.ellipse", place.address)
            infoRow("clock", place.openingHoursText)
            HStack(spacing: 8) {
                Button(action: onAdd) {
                    Label(inRoute ? "已加入路線" : "加入路線", systemImage: inRoute ? "checkmark" : "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MapTheme.accent)
                .disabled(inRoute)

                Menu {
                    Button("設為起點", systemImage: "flag", action: onSetOrigin)
                    Button("設為終點", systemImage: "flag.checkered", action: onSetDestination)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 22, height: 20)
                }
                .buttonStyle(.bordered)
                .tint(MapTheme.textSecondary)
                .accessibilityLabel("更多操作")
            }
            .controlSize(.regular)
        }
        .mapCard()
    }

    private func infoRow(_ icon: String, _ text: String?) -> some View {
        Label {
            Text(text ?? "未提供")
                .foregroundStyle(text == nil ? MapTheme.textSecondary : MapTheme.textPrimary)
                .lineLimit(2)
        } icon: {
            Image(systemName: icon).foregroundStyle(MapTheme.textSecondary)
        }
        .font(.subheadline)
    }
}

// MARK: - 站點資訊卡（起點、終點、站點）

struct WaypointCard: View {
    var title: String
    var role: String
    var problem: Bool
    var deleteTitle: String
    var onDelete: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).lineLimit(2)
                    Text(role).font(.caption.weight(.semibold)).foregroundStyle(problem ? .red : MapTheme.accentOnDark)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(MapTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(MapTheme.elevated, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("關閉")
            }
            if problem {
                Text("這個站點離步行道路太遠，無法規劃路線。")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            Text("長按地圖上的其他位置，可以把這個點移過去。")
                .font(.footnote)
                .foregroundStyle(MapTheme.textSecondary)
            Button(role: .destructive, action: onDelete) {
                Label(deleteTitle, systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .mapCard()
    }
}

// MARK: - 路線摘要卡

struct RouteSummaryCard: View {
    var planner: PlannerStore
    var onOpenRun: () -> Void
    var onFocusProblem: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("\(planner.plan.stops.count) 個站點")
                    .font(.subheadline.weight(.bold))
                if let r = planner.result, planner.resultStatus != .none {
                    Text("·").foregroundStyle(MapTheme.textSecondary)
                    Text(Fmt.distance(r.distanceMeters))
                        .font(.subheadline.weight(.semibold))
                    Text("·").foregroundStyle(MapTheme.textSecondary)
                    Text(Fmt.duration(r.totalDurationSeconds))
                        .font(.subheadline.weight(.semibold))
                }
                Spacer(minLength: 4)
                statusTag
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            statusLine

            HStack(spacing: 8) {
                Button {
                    planner.computeRoute()
                } label: {
                    Group {
                        if planner.routingState == .computing {
                            HStack(spacing: 6) { ProgressView().tint(.white); Text("計算中") }
                        } else {
                            Label(planner.resultStatus == .none ? "計算路線" : "重新計算", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(MapTheme.accent)
                .disabled(!planner.canCompute || planner.routingState == .computing)

                Button(action: onOpenRun) {
                    Label("路跑編輯", systemImage: "list.number")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(MapTheme.textPrimary)
            }
        }
        .mapCard()
    }

    @ViewBuilder private var statusTag: some View {
        switch planner.resultStatus {
        case .stale: tag("路線需重新計算", MapTheme.accentOnDark)
        case .savedEstimate: tag("已儲存的估算", .blue)
        default: EmptyView()
        }
    }

    private func tag(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.14), in: Capsule())
    }

    @ViewBuilder private var statusLine: some View {
        if case .failed(let e) = planner.routingState {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.routingMessage(e)).font(.footnote).foregroundStyle(.red)
                    if e.code == .noWalkableRoute, !e.waypointIds.isEmpty {
                        Button("查看紅色站點", action: onFocusProblem).font(.footnote.weight(.semibold))
                    }
                }
            }
        } else if !planner.canCompute {
            Text("還需要：" + planner.plan.missingRequirements.joined(separator: "、") + "。長按地圖可設定起終點。")
                .font(.footnote)
                .foregroundStyle(MapTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(endText)
                .font(.footnote)
                .foregroundStyle(MapTheme.textSecondary)
                .lineLimit(1)
        }
    }

    private var endText: String {
        let origin = planner.plan.origin?.name ?? "未設定"
        switch planner.plan.endMode {
        case .returnToOrigin: return "起點：\(origin) · 回到起點"
        case .custom: return "起點：\(origin) · 終點：\(planner.plan.destination?.name ?? "未設定")"
        }
    }

    static func routingMessage(_ e: ServiceError) -> String {
        switch e.code {
        case .noWalkableRoute: "有站點無法步行抵達。請移動或刪除紅色站點後重試。"
        case .outsideServiceArea: "有站點在服務範圍外，請調整後重試。"
        case .upstreamTimeout: "路線計算逾時，請稍後按「重新計算」。"
        case .upstreamUnavailable: "路線服務暫時無法使用，請稍後重試。"
        case .rateLimited: "請求太頻繁，請稍候再試。"
        default: e.message.isEmpty ? "路線計算失敗，請稍後再試。" : e.message
        }
    }
}

// MARK: - 搜尋結果清單

struct PlaceResultsPanel: View {
    var state: MapScreenState
    var planner: PlannerStore
    var onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(header).font(.subheadline.weight(.bold))
                Spacer()
                Button {
                    state.listExpanded = false
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .frame(width: 30, height: 30)
                        .background(MapTheme.elevated, in: Circle())
                }
                .tint(MapTheme.textSecondary)
                .accessibilityLabel("收合清單")
            }
            .padding(.bottom, 6)
            content
        }
        .mapCard()
    }

    private var header: String {
        switch state.searchStatus {
        case .loaded: "找到 \(state.visiblePlaces.count) 間"
        case .loading: "正在載入酒吧…"
        default: "搜尋結果"
        }
    }

    @ViewBuilder private var content: some View {
        switch state.searchStatus {
        case .idle:
            message("酒吧資料尚未載入。", icon: "magnifyingglass")
        case .loading:
            HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 16)
        case .failed(let text):
            VStack(spacing: 8) {
                message(text, icon: "wifi.exclamationmark")
                Button("重試", action: onRetry).buttonStyle(.bordered).tint(MapTheme.accent)
            }
            .frame(maxWidth: .infinity)
        case .loaded:
            if state.visiblePlaces.isEmpty {
                message(state.places.isEmpty ? "目前沒有酒吧資料。" : "沒有符合篩選的店家。", icon: "wineglass")
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(state.visiblePlaces) { place in
                            row(place)
                            Divider()
                        }
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }

    private func row(_ place: Place) -> some View {
        let added = planner.contains(placeId: place.id)
        return HStack(spacing: 10) {
            Button {
                state.select(place, moveCamera: true)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.name).font(.subheadline.weight(.semibold)).foregroundStyle(MapTheme.textPrimary).lineLimit(1)
                    Text("\(MapTheme.categoryText(place.category)) · \(place.address ?? "地址未提供")")
                        .font(.caption).foregroundStyle(MapTheme.textSecondary).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Button {
                planner.addStop(Waypoint.from(place), maxStops: state.maxStops)
            } label: {
                Image(systemName: added ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(added ? MapTheme.textSecondary : MapTheme.accentOnDark)
            }
            .buttonStyle(.plain)
            .disabled(added)
            .accessibilityLabel(added ? "已加入路線" : "加入路線")
        }
        .padding(.vertical, 8)
    }

    private func message(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(MapTheme.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
    }
}

// MARK: - 授權標示

struct AttributionBar: View {
    var attributions: [Attribution]
    @Environment(\.openURL) private var openURL

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), alignment: .leading)], alignment: .leading, spacing: 4) {
            ForEach(attributions, id: \.self) { a in
                Button(a.text) { openURL(a.url) }
                    .buttonStyle(.plain)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.caption2)
        .foregroundStyle(MapTheme.textSecondary)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(MapTheme.surface, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("地圖資料來源")
    }
}
