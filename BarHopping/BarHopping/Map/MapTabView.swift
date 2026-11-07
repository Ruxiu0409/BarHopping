import SwiftUI
import UIKit

/// 地圖分頁根畫面：MapLibre 底圖、酒吧搜尋、站點與路線顯示。
/// 所有規劃編輯都透過 `PlannerStore`；地圖自己的狀態放在 `MapScreenState`。
struct MapTabView: View {
    @Environment(PlannerStore.self) private var planner
    @Environment(AppRouter.self) private var router
    @Environment(\.openURL) private var openURL
    @State private var screen = MapScreenState()
    @State private var customStopCoordinate: Coordinate?
    @State private var customStopName = ""
    @State private var mapFrame: CGRect = .zero
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            MapLibreMapView(state: screen,
                            model: renderModel,
                            styleURL: screen.styleURL,
                            styleReloadToken: screen.styleReloadToken,
                            cameraCommand: screen.cameraCommand,
                            showsUserLocation: screen.showsUserLocation)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                topControls
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).maxY } action: { maxY in
                        screen.overlayInsets.top = max(0, maxY - mapFrame.minY)
                    }
                Spacer(minLength: 0)
                bottomStack
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .global).minY } action: { minY in
                        screen.overlayInsets.bottom = max(0, mapFrame.maxY - minY)
                    }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 8)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { mapFrame = $0 }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.dark)
        .foregroundStyle(MapTheme.textPrimary)
        .toolbarBackground(.visible, for: .tabBar)
        .onAppear {
            screen.loadConfigIfNeeded(api: planner.api)
            handleRouterFocus()
            consumeNotice()
            screen.refreshConvenienceStores()
        }
        .onDisappear { screen.cancelConvenienceQuery() }
        .onChange(of: router.mapFocusRouteRequest) { handleRouterFocus() }
        .onChange(of: planner.notice) { consumeNotice() }
        .task(id: screen.toast) {
            guard screen.toast != nil else { return }
            try? await Task.sleep(for: .seconds(2.5))
            if !Task.isCancelled { withAnimation { screen.toast = nil } }
        }
        .confirmationDialog("這個位置", isPresented: longPressBinding, titleVisibility: .visible,
                            presenting: screen.pendingCoordinate) { c in
            longPressActions(c)
        }
        .alert("新增自訂站點", isPresented: customStopBinding) {
            TextField("站點名稱", text: $customStopName)
            Button("新增") { addCustomStop() }
                .disabled(customStopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            Button("取消", role: .cancel) { customStopCoordinate = nil }
        } message: {
            Text("請輸入名稱（不可空白）。自訂站點只會保存在這條路線中。")
        }
        .animation(.snappy(duration: 0.25), value: screen.selection)
        .animation(.snappy(duration: 0.25), value: screen.listExpanded)
        .animation(.snappy(duration: 0.25), value: screen.userMovedMap)
    }

    // MARK: - 上方：搜尋列、篩選、提示

    private var topControls: some View {
        VStack(spacing: 8) {
            searchBar
            chips
            if screen.showsConvenienceStores { convenienceControls }
            if screen.userMovedMap && screen.searchStatus != .loading {
                Button {
                    searchFocused = false
                    screen.searchCurrentArea(api: planner.api)
                } label: {
                    Label("搜尋這個區域", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 10)
                        .background(MapTheme.accent, in: Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                .transition(.scale.combined(with: .opacity))
            }
            banners
            HStack {
                Spacer()
                rightButtons
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "wineglass.fill")
                .foregroundStyle(MapTheme.accent)
                .font(.title3)
                .padding(.leading, 4)
            Divider().frame(height: 24)
            TextField("搜尋酒吧名稱", text: $screen.queryText)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { screen.searchCurrentArea(api: planner.api) }
                .autocorrectionDisabled()
            if screen.searchStatus == .loading {
                ProgressView().controlSize(.small)
            } else if !screen.queryText.isEmpty {
                Button {
                    screen.queryText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
                .accessibilityLabel("清除搜尋文字")
            }
            Button {
                searchFocused = false
                screen.searchCurrentArea(api: planner.api)
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(MapTheme.accent, in: Circle())
            }
            .accessibilityLabel("在這個區域搜尋")
        }
        .padding(.leading, 12).padding(.trailing, 5)
        .frame(height: 48)
        .background(MapTheme.elevated, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("全部", selected: screen.categoryFilter == nil) { screen.categoryFilter = nil }
                chip("酒吧", selected: screen.categoryFilter == .bar) { screen.categoryFilter = .bar }
                chip("Pub", selected: screen.categoryFilter == .pub) { screen.categoryFilter = .pub }
                chip("超商", systemImage: "storefront", selected: screen.showsConvenienceStores) {
                    screen.toggleConvenienceStores()
                }
                chip(listChipTitle, systemImage: screen.listExpanded ? "chevron.down" : "list.bullet",
                     selected: screen.listExpanded) {
                    screen.selection = nil
                    screen.listExpanded.toggle()
                }
            }
            .padding(.horizontal, 2).padding(.vertical, 3)
        }
    }

    private var convenienceControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                chip("全部", selected: screen.convenienceBrand == nil) { screen.filterConvenienceStores(nil) }
                ForEach(ConvenienceBrand.allCases, id: \.self) { brand in
                    chip(brand.rawValue, selected: screen.convenienceBrand == brand) {
                        screen.filterConvenienceStores(brand)
                    }
                }
                Spacer(minLength: 0)
            }
            if screen.convenienceStatus == .failed {
                Button { screen.refreshConvenienceStores() } label: { convenienceStatusLabel }
                    .buttonStyle(.plain)
            } else {
                convenienceStatusLabel
            }
        }
    }

    private var convenienceStatusLabel: some View {
        Label(screen.convenienceStatusText, systemImage: "storefront")
            .font(.caption)
            .foregroundStyle(MapTheme.textSecondary)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(MapTheme.surface, in: Capsule())
    }

    private var listChipTitle: String {
        screen.searchStatus == .loaded ? "清單 \(screen.visiblePlaces.count)" : "清單"
    }

    private func chip(_ title: String, systemImage: String? = nil, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if let systemImage { Image(systemName: systemImage).font(.caption.weight(.bold)) }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(selected ? MapTheme.accent : MapTheme.textPrimary)
            .padding(.horizontal, 14).frame(height: 34)
            .background(MapTheme.elevated, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? MapTheme.accent : MapTheme.separator, lineWidth: selected ? 1.5 : 0.5))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    @ViewBuilder private var banners: some View {
        if let toast = screen.toast {
            banner(icon: "info.circle.fill", text: toast, tint: MapTheme.accent)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
        if let error = screen.mapLoadError {
            banner(icon: "map", text: error, tint: .red) {
                Button("重試") { screen.retryMapLoad() }.font(.subheadline.weight(.bold))
            }
        }
        if let problem = screen.locationProblem {
            banner(icon: "location.slash", text: problem.message, tint: .secondary) {
                VStack(spacing: 6) {
                    if problem == .denied {
                        Button("設定") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                        .font(.subheadline.weight(.bold))
                    }
                    Button {
                        screen.locationProblem = nil
                    } label: {
                        Image(systemName: "xmark").font(.footnote.weight(.bold))
                    }
                    .tint(.secondary)
                    .accessibilityLabel("關閉")
                }
            }
        }
    }

    private func banner(icon: String, text: String, tint: Color,
                        @ViewBuilder trailing: () -> some View = { EmptyView() }) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(text).font(.footnote).frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            trailing()
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(MapTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        .tint(MapTheme.accent)
    }

    private var rightButtons: some View {
        VStack(spacing: 10) {
            Button {
                screen.showPlacePins.toggle()
            } label: {
                MapRoundButtonLabel(systemImage: "square.3.layers.3d", active: screen.showPlacePins)
            }
            .accessibilityLabel(screen.showPlacePins ? "隱藏酒吧圖釘" : "顯示酒吧圖釘")

            if !routeFitCoordinates.isEmpty {
                Button {
                    focusRoute()
                } label: {
                    MapRoundButtonLabel(systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                }
                .accessibilityLabel("顯示整條路線")
            }

            Menu {
                Button("移到我的位置", systemImage: "location") {
                    screen.locate(intent: .center, planner: planner)
                }
                Button("用目前位置當起點", systemImage: "flag") {
                    screen.locate(intent: .setOrigin, planner: planner)
                }
            } label: {
                if screen.isLocating {
                    ProgressView()
                        .frame(width: 46, height: 46)
                        .background(MapTheme.elevated, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                } else {
                    MapRoundButtonLabel(systemImage: screen.showsUserLocation ? "location.fill" : "location")
                }
            }
            .disabled(screen.isLocating)
            .accessibilityLabel("定位")
        }
    }

    // MARK: - 下方：授權標示與卡片

    private var bottomStack: some View {
        VStack(alignment: .leading, spacing: 8) {
            AttributionBar(attributions: screen.attributions)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let card = selectionCard {
                card.transition(.move(edge: .bottom).combined(with: .opacity))
            } else if screen.listExpanded {
                PlaceResultsPanel(state: screen, planner: planner,
                                  onRetry: { screen.retrySearch(api: planner.api) },
                                  onLoadMore: { screen.loadMore(api: planner.api) })
                    .frame(maxHeight: 280)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if hasPlan {
                RouteSummaryCard(planner: planner,
                                 onOpenRun: { router.selectedTab = .run },
                                 onFocusProblem: focusProblemWaypoints)
            }
        }
    }

    private var selectionCard: AnyView? {
        switch screen.selection {
        case .place(let place):
            return AnyView(PlaceCard(
                place: place,
                inRoute: planner.contains(placeId: place.id),
                onAdd: { planner.addStop(Waypoint.from(place), maxStops: screen.maxStops) },
                onSetOrigin: { planner.setOrigin(Waypoint.from(place)) },
                onSetDestination: { planner.setDestination(Waypoint.from(place)) },
                onClose: { screen.selection = nil }))
        case .convenienceStore(let store):
            return AnyView(ConvenienceStoreCard(
                store: store,
                onAdd: {
                    if planner.addStop(Waypoint.custom(name: store.name, at: store.coordinate), maxStops: screen.maxStops) {
                        screen.selection = nil
                        screen.toast = "已加入自訂站點「\(store.name)」"
                    }
                },
                onClose: { screen.selection = nil }))
        case .waypoint(let id):
            guard let info = waypointInfo(id) else { return nil }
            return AnyView(WaypointCard(
                title: info.waypoint.name, role: info.role, problem: problemIds.contains(id),
                deleteTitle: info.deleteTitle,
                onDelete: {
                    info.delete()
                    screen.selection = nil
                },
                onClose: { screen.selection = nil }))
        case nil:
            return nil
        }
    }

    private struct WaypointInfo {
        var waypoint: Waypoint
        var role: String
        var deleteTitle: String
        var delete: () -> Void
    }

    private func waypointInfo(_ id: String) -> WaypointInfo? {
        let plan = planner.plan
        if let o = plan.origin, o.id == id {
            return WaypointInfo(waypoint: o, role: plan.endMode == .returnToOrigin ? "起點（也是終點）" : "起點",
                                deleteTitle: "移除起點") { planner.setOrigin(nil) }
        }
        if let d = plan.destination, d.id == id {
            return WaypointInfo(waypoint: d, role: "終點", deleteTitle: "改為回到起點") { planner.setReturnToOrigin() }
        }
        if let i = plan.stops.firstIndex(where: { $0.id == id }) {
            let s = plan.stops[i]
            return WaypointInfo(waypoint: s.waypoint, role: "第 \(i + 1) 站 · 停留 \(Fmt.minutes(s.dwellMinutes))",
                                deleteTitle: "從路線移除") { planner.removeStop(id: id) }
        }
        return nil
    }

    private var hasPlan: Bool {
        let p = planner.plan
        return p.origin != nil || !p.stops.isEmpty || p.destination != nil || planner.result != nil
    }

    // MARK: - 長按選單與自訂站點

    private var longPressBinding: Binding<Bool> {
        Binding(get: { screen.pendingCoordinate != nil },
                set: { if !$0 { screen.pendingCoordinate = nil } })
    }

    private var customStopBinding: Binding<Bool> {
        Binding(get: { customStopCoordinate != nil },
                set: { if !$0 { customStopCoordinate = nil } })
    }

    @ViewBuilder private func longPressActions(_ c: Coordinate) -> some View {
        Button("設為起點") { planner.setOrigin(Waypoint.custom(name: "自訂起點", at: c)) }
        Button("設為終點") { planner.setDestination(Waypoint.custom(name: "自訂終點", at: c)) }
        Button("新增自訂站點") {
            customStopName = ""
            customStopCoordinate = c
        }
        if case .waypoint(let id) = screen.selection, let info = waypointInfo(id) {
            Button("將「\(info.waypoint.name)」移到這裡") { planner.moveWaypoint(id: id, to: c) }
        }
        Button("取消", role: .cancel) {}
    }

    private func addCustomStop() {
        let name = customStopName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let c = customStopCoordinate else { return }
        customStopCoordinate = nil
        guard !name.isEmpty else {
            screen.toast = "自訂站點名稱不可空白"
            return
        }
        planner.addStop(Waypoint.custom(name: name, at: c), maxStops: screen.maxStops)
    }

    // MARK: - 通知與鏡頭

    private func consumeNotice() {
        guard let n = planner.notice else { return }
        withAnimation { screen.toast = n }
        planner.notice = nil
    }

    private func handleRouterFocus() {
        guard router.mapFocusRouteRequest != screen.handledRouterFocus else { return }
        screen.handledRouterFocus = router.mapFocusRouteRequest
        focusRoute()
    }

    private func focusRoute() {
        let coords = routeFitCoordinates
        guard !coords.isEmpty else { return }
        screen.send(.fit(coords))
    }

    private func focusProblemWaypoints() {
        let ids = problemIds
        let wps = allWaypoints.filter { ids.contains($0.id) }
        guard let first = wps.first else { return }
        screen.selection = .waypoint(first.id)
        screen.send(.fit(wps.map(\.coordinate)))
    }

    private var allWaypoints: [Waypoint] {
        let p = planner.plan
        return [p.origin].compactMap { $0 } + p.stops.map(\.waypoint) + [p.destination].compactMap { $0 }
    }

    private var routeFitCoordinates: [Coordinate] {
        var coords = allWaypoints.map(\.coordinate)
        if let r = planner.result, planner.resultStatus != .none {
            coords += r.legs.flatMap(\.geometry.points)
        }
        return coords
    }

    private var problemIds: Set<String> {
        if case .failed(let e) = planner.routingState, e.code == .noWalkableRoute { return Set(e.waypointIds) }
        return []
    }

    // MARK: - 地圖內容

    private var renderModel: MapRenderModel {
        var m = MapRenderModel()
        m.convenienceStores = screen.showsConvenienceStores ? screen.convenienceStores : []
        let plan = planner.plan
        let problems = problemIds
        let selectedWaypoint: String? = if case .waypoint(let id) = screen.selection { id } else { nil }
        let selectedPlace: String? = if case .place(let p) = screen.selection { p.id } else { nil }

        if screen.showPlacePins {
            var pins = screen.visiblePlaces.map { p in
                MapRenderModel.PlacePin(id: p.id, name: p.name, coordinate: p.coordinate,
                                        state: p.id == selectedPlace ? .selected : (planner.contains(placeId: p.id) ? .inRoute : .normal))
            }
            // 從清單選到但不在目前結果中的店家也要顯示
            if case .place(let p) = screen.selection, !pins.contains(where: { $0.id == p.id }) {
                pins.append(.init(id: p.id, name: p.name, coordinate: p.coordinate, state: .selected))
            }
            m.places = pins
        } else if case .place(let p) = screen.selection {
            m.places = [.init(id: p.id, name: p.name, coordinate: p.coordinate, state: .selected)]
        }

        func pin(_ w: Waypoint, _ label: String, _ kind: MapRenderModel.WaypointPin.Kind) -> MapRenderModel.WaypointPin {
            .init(id: w.id, coordinate: w.coordinate, label: label,
                  kind: problems.contains(w.id) ? .problem : kind, selected: w.id == selectedWaypoint)
        }
        if let o = plan.origin { m.waypoints.append(pin(o, "起", .origin)) }
        for (i, s) in plan.stops.enumerated() { m.waypoints.append(pin(s.waypoint, "\(i + 1)", .stop)) }
        if plan.endMode == .custom, let d = plan.destination { m.waypoints.append(pin(d, "終", .destination)) }
        if let c = screen.pendingCoordinate ?? customStopCoordinate {
            m.waypoints.append(.init(id: "pending", coordinate: c, label: "", kind: .pending, selected: false))
        }

        if let r = planner.result, planner.resultStatus != .none {
            m.legs = r.legs.map(\.geometry.points)
            m.routeFaded = planner.resultStatus == .stale
            // 路網配對點：只在與原座標明顯不同時另外畫小點
            let byId = Dictionary(allWaypoints.map { ($0.id, $0.coordinate) }, uniquingKeysWith: { a, _ in a })
            var snapped: [Coordinate] = []
            for leg in r.legs {
                for (id, s) in [(leg.fromWaypointId, leg.snappedFrom), (leg.toWaypointId, leg.snappedTo)] {
                    guard let original = byId[id], Self.meters(original, s) > 3,
                          !snapped.contains(where: { Self.meters($0, s) < 1 }) else { continue }
                    snapped.append(s)
                }
            }
            m.snappedPoints = snapped
        }
        return m
    }

    /// 近距離的約略公尺數（只用於判斷是否另外畫配對點）。
    private static func meters(_ a: Coordinate, _ b: Coordinate) -> Double {
        let dLat = (a.latitude - b.latitude) * 111_320
        let dLon = (a.longitude - b.longitude) * 111_320 * cos(a.latitude * .pi / 180)
        return (dLat * dLat + dLon * dLon).squareRoot()
    }
}
