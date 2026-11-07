import SwiftUI

/// 路跑分頁：編輯目前路線、調整站序、計算路線與管理已儲存的路線。
/// 所有編輯都透過共用的 PlannerStore，與地圖分頁同步。
struct RunTabView: View {
    @Environment(PlannerStore.self) private var planner
    @Environment(AppRouter.self) private var router

    @State private var titleText = ""
    @FocusState private var titleFocused: Bool

    /// 最近一次儲存或載入時的 planVersion，用來判斷是否有未儲存的變更。
    @State private var savedVersion: Int?
    /// 路由失敗時的 planVersion，用來判斷錯誤是否仍對應目前規劃。
    @State private var failedVersion: Int?

    @State private var toast: Toast?
    @State private var toastTask: Task<Void, Never>?
    @State private var isSaving = false
    @State private var showDrafts = false
    @State private var confirmNewPlan = false

    private var plan: RoutePlan { planner.plan }

    var body: some View {
        NavigationStack {
            List {
                statusSection
                planSection
                stopsSection
                computeSection
                if let result = planner.result {
                    RunResultSection(result: result, plan: plan, isDimmed: planner.resultStatus == .stale)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("路跑")
            .toolbar { toolbar }
            .overlay(alignment: .top) { toastView }
            .sheet(isPresented: $showDrafts) {
                SavedDraftsView(drafts: planner.drafts,
                                currentPlanId: plan.id,
                                hasUnsavedChanges: hasUnsavedChanges) { draft in
                    planner.load(draft)
                    savedVersion = planner.planVersion
                    titleText = planner.plan.title
                    showToast("已載入「\(draft.plan.title)」")
                }
            }
            .confirmationDialog("開始新路線？", isPresented: $confirmNewPlan, titleVisibility: .visible) {
                Button("開始新路線", role: .destructive) {
                    planner.startNewPlan()
                    savedVersion = planner.planVersion
                    titleText = planner.plan.title
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text(hasUnsavedChanges ? "目前的規劃有未儲存的變更，開始新路線後會消失。" : "目前的規劃會被清空。")
            }
        }
        .tint(RunTheme.accent)
        .onAppear {
            titleText = plan.title
            consumeNotice()
        }
        .onChange(of: plan.title) { _, new in
            if !titleFocused { titleText = new }
        }
        .onChange(of: planner.notice) { _, _ in consumeNotice() }
        .onChange(of: planner.routingState) { _, new in
            if case .failed = new { failedVersion = planner.planVersion }
        }
    }

    // MARK: - 狀態（過期、錯誤、已儲存估算）

    @ViewBuilder
    private var statusSection: some View {
        if planner.result != nil && planner.resultStatus == .stale && planner.routingState != .computing {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("路線需重新計算", systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                        .foregroundStyle(RunTheme.accent)
                    Text("規劃已修改，下方結果是修改前的估算。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button("重新計算") { planner.computeRoute() }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canCompute)
                }
                .padding(.vertical, 4)
            }
        }
        if let error = routingError {
            errorSection(error)
        }
    }

    private var routingError: ServiceError? {
        if case .failed(let e) = planner.routingState { return e }
        return nil
    }

    /// 錯誤發生後規劃是否沒有再修改過。
    private var errorIsCurrent: Bool { failedVersion == planner.planVersion }

    /// NO_WALKABLE_ROUTE 指出、且仍在目前規劃中的站點 id。
    private var problemIds: Set<String> {
        guard let e = routingError, e.code == .noWalkableRoute, errorIsCurrent else { return [] }
        return Set(e.waypointIds)
    }

    private func errorSection(_ error: ServiceError) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label(error.runTitle, systemImage: "exclamationmark.octagon.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text(error.runExplanation)
                    .font(.subheadline)
                if !error.message.isEmpty {
                    Text("服務訊息：\(error.message)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !errorIsCurrent {
                    Text("規劃已在錯誤後修改，可以再試一次。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)

            if error.code == .noWalkableRoute {
                ForEach(problemWaypoints, id: \.waypoint.id) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Label(item.label, systemImage: "mappin.slash")
                            .foregroundStyle(.red)
                        HStack {
                            Button("在地圖上移動") { router.showRouteOnMap() }
                                .accessibilityLabel("在地圖上移動 \(item.waypoint.name)")
                            if item.isStop {
                                Button("刪除這站", role: .destructive) { planner.removeStop(id: item.waypoint.id) }
                                    .tint(.red)
                                    .accessibilityLabel("刪除 \(item.waypoint.name)")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 2)
                }
            }

            if error.runShowsRetry {
                Button {
                    planner.computeRoute()
                } label: {
                    Label("重試", systemImage: "arrow.clockwise")
                }
                .disabled(!canCompute)
            }
        }
    }

    private struct ProblemWaypoint {
        let waypoint: Waypoint
        let label: String
        let isStop: Bool
    }

    private var problemWaypoints: [ProblemWaypoint] {
        let ids = problemIds
        var out: [ProblemWaypoint] = []
        if let o = plan.origin, ids.contains(o.id) { out.append(.init(waypoint: o, label: "起點：\(o.name)", isStop: false)) }
        for (i, s) in plan.stops.enumerated() where ids.contains(s.id) {
            out.append(.init(waypoint: s.waypoint, label: "第 \(i + 1) 站：\(s.waypoint.name)", isStop: true))
        }
        if let d = plan.destination, ids.contains(d.id) { out.append(.init(waypoint: d, label: "終點：\(d.name)", isStop: false)) }
        return out
    }

    // MARK: - 標題、起點、終點

    private var planSection: some View {
        Section {
            TextField("路線名稱", text: $titleText)
                .font(.title3.bold())
                .focused($titleFocused)
                .submitLabel(.done)
                .onSubmit(commitTitle)
                .onChange(of: titleFocused) { _, focused in if !focused { commitTitle() } }
                .accessibilityLabel("路線名稱")

            endpointRow(title: "起點", waypoint: plan.origin, icon: "figure.walk.circle.fill",
                        missingText: "到地圖使用目前位置或長按地圖設定起點")

            Picker("終點", selection: Binding(
                get: { customEndRequested ? .custom : plan.endMode },
                set: { mode in
                    if mode == .returnToOrigin {
                        customEndRequested = false
                        if plan.endMode != .returnToOrigin { planner.setReturnToOrigin() }
                    } else if plan.endMode == .custom {
                        return
                    } else if let d = plan.destination {
                        planner.setDestination(d)
                    } else {
                        customEndRequested = true
                    }
                })) {
                Text("回到起點").tag(EndMode.returnToOrigin)
                Text("自訂終點").tag(EndMode.custom)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("終點模式")

            if plan.endMode == .custom || customEndRequested {
                endpointRow(title: "終點", waypoint: plan.destination, icon: "flag.checkered.circle.fill",
                            missingText: "長按地圖設定終點")
            } else {
                Label("走完最後一站後回到起點", systemImage: "arrow.uturn.backward.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("路線")
        }
        .onChange(of: plan.endMode) { _, _ in customEndRequested = false }
    }

    /// 選了「自訂終點」但還沒有終點：PlannerStore 需要 Waypoint 才能切換，先引導到地圖。
    @State private var customEndRequested = false

    @ViewBuilder
    private func endpointRow(title: String, waypoint: Waypoint?, icon: String, missingText: String) -> some View {
        if let waypoint {
            let isProblem = problemIds.contains(waypoint.id)
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.caption).foregroundStyle(.secondary)
                    Text(waypoint.name).foregroundStyle(isProblem ? .red : .primary)
                }
            } icon: {
                Image(systemName: icon).foregroundStyle(isProblem ? .red : RunTheme.accent)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title)：\(waypoint.name)\(isProblem ? "，找不到可步行的道路" : "")")
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("尚未設定\(title)").font(.subheadline.bold())
                        Text(missingText).font(.footnote).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: icon).foregroundStyle(.secondary)
                }
                Button("到地圖設定") { router.selectedTab = .map }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("到地圖設定\(title)")
            }
            .padding(.vertical, 2)
        }
    }

    private func commitTitle() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            titleText = plan.title
        } else if trimmed != plan.title {
            planner.setTitle(trimmed)
        }
    }

    // MARK: - 站點

    private var stopsSection: some View {
        Section {
            if plan.stops.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "wineglass")
                        .font(.largeTitle)
                        .foregroundStyle(RunTheme.accent)
                        .accessibilityHidden(true)
                    Text("還沒有酒吧").font(.headline)
                    Text("到地圖搜尋或瀏覽酒吧，加入路線後會出現在這裡。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("到地圖找酒吧") { router.selectedTab = .map }
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            } else {
                ForEach(Array(plan.stops.enumerated()), id: \.element.id) { i, stop in
                    RunStopRow(stop: stop, index: i, count: plan.stops.count,
                               isProblem: problemIds.contains(stop.id),
                               onDwell: { planner.setDwell(id: stop.id, minutes: $0) },
                               onMove: { planner.moveStop(id: stop.id, by: $0) },
                               onDelete: { planner.removeStop(id: stop.id) })
                }
                .onMove { planner.moveStops(from: $0, to: $1) }
                .onDelete { offsets in
                    let ids = offsets.map { plan.stops[$0].id }
                    ids.forEach { planner.removeStop(id: $0) }
                }
            }
        } header: {
            HStack {
                Text("站點")
                Spacer()
                Text("\(plan.stops.count) / \(RoutePlan.maxStops)")
                    .monospacedDigit()
                    .accessibilityLabel("已加入 \(plan.stops.count) 間，最多 \(RoutePlan.maxStops) 間")
            }
        } footer: {
            if plan.stops.count > 1 {
                Text("長按並拖曳可調整順序，或使用上移／下移按鈕。")
            }
        }
    }

    // MARK: - 計算

    private var computeSection: some View {
        Section {
            if planner.routingState == .computing {
                HStack(spacing: 12) {
                    ProgressView()
                    Text("計算路線中…")
                    Spacer()
                    Button("取消") { planner.cancelRouting() }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                }
                .accessibilityElement(children: .contain)
            } else {
                Button {
                    planner.computeRoute()
                } label: {
                    Label(planner.result == nil ? "計算路線" : "重新計算路線", systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canCompute)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if !missingRequirements.isEmpty {
                Text("還缺：\(missingRequirements.joined(separator: "、"))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if planner.resultStatus == .savedEstimate {
                Label("已儲存的估算", systemImage: "bookmark.fill")
                    .font(.subheadline)
                    .foregroundStyle(RunTheme.accent)
                    .accessibilityHint("這是儲存時的結果，可以重新計算取得最新路線")
            }

            if planner.result != nil || !plan.stops.isEmpty {
                Button {
                    router.showRouteOnMap()
                } label: {
                    Label("在地圖查看", systemImage: "map")
                }
            }
        }
    }

    // MARK: - 工具列與草稿

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Button {
                    showDrafts = true
                } label: {
                    Label("已儲存的路線", systemImage: "bookmark")
                }
                Button {
                    confirmNewPlan = true
                } label: {
                    Label("新路線", systemImage: "plus")
                }
            } label: {
                Label("更多", systemImage: "ellipsis.circle")
            }
            .accessibilityLabel("路線選項")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await save() }
            } label: {
                if isSaving {
                    ProgressView()
                } else {
                    Text("儲存")
                }
            }
            .disabled(isSaving)
            .accessibilityLabel("儲存路線")
        }
    }

    /// 使用者選了「自訂終點」但尚未在地圖設定時，也視為缺少終點（PlannerStore 仍是回到起點）。
    private var missingRequirements: [String] {
        var m = plan.missingRequirements
        if customEndRequested && plan.endMode == .returnToOrigin { m.append("終點") }
        return m
    }

    private var canCompute: Bool { planner.canCompute && missingRequirements.isEmpty }

    private var planHasContent: Bool {
        plan.origin != nil || !plan.stops.isEmpty || plan.destination != nil || plan.title != RoutePlan.empty().title
    }

    private var hasUnsavedChanges: Bool {
        planHasContent && savedVersion != planner.planVersion
    }

    private func save() async {
        commitTitle()
        isSaving = true
        defer { isSaving = false }
        let version = planner.planVersion
        do {
            try await planner.saveDraft()
            savedVersion = version
            showToast("已儲存「\(plan.title)」")
        } catch {
            let message = (error as? ServiceError)?.message ?? error.localizedDescription
            showToast("儲存失敗：\(message)", isError: true)
        }
    }

    // MARK: - 提示

    private struct Toast: Equatable {
        let id = UUID()
        let text: String
        let isError: Bool
    }

    private func consumeNotice() {
        guard let n = planner.notice else { return }
        planner.notice = nil
        showToast(n, isError: true)
    }

    private func showToast(_ text: String, isError: Bool = false) {
        toastTask?.cancel()
        toast = Toast(text: text, isError: isError)
        AccessibilityNotification.Announcement(text).post()
        toastTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation { toast = nil }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if let toast {
            Label(toast.text, systemImage: toast.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(toast.isError ? Color.red.opacity(0.92) : RunTheme.accent))
                .shadow(radius: 6, y: 2)
                .padding(.horizontal)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { withAnimation { self.toast = nil } }
                .id(toast.id)
                .accessibilityAddTraits(.isStaticText)
        }
    }
}

#Preview("有站點") {
    let planner = PlannerStore(api: MockBarHoppingAPI(), drafts: InMemoryDraftStore())
    planner.setOrigin(.custom(name: "草悟道", at: Coordinate(latitude: 24.1513, longitude: 120.6631)))
    planner.addStop(.custom(name: "勤美微醺小酒館", at: Coordinate(latitude: 24.1508, longitude: 120.6640)))
    planner.addStop(.custom(name: "一中街啤酒屋", at: Coordinate(latitude: 24.1495, longitude: 120.6853)))
    planner.addStop(.custom(name: "七期威士忌吧", at: Coordinate(latitude: 24.1625, longitude: 120.6400)))
    return RunTabView()
        .environment(planner)
        .environment(AppRouter())
}

#Preview("空白") {
    RunTabView()
        .environment(PlannerStore(api: MockBarHoppingAPI(), drafts: InMemoryDraftStore()))
        .environment(AppRouter())
}
