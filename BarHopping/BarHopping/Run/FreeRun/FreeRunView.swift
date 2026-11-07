import SwiftUI

struct FreeRunView: View {
    let onCollapse: () -> Void
    let onComplete: (FreeRunSession) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @Environment(DrinkPassStore.self) private var passes
    @State private var store: FreeRunStore
    @State private var confirmEnd = false
    @State private var showsNearbyBars = false
    @State private var panelExpanded = false
    @State private var showsSafeRide = false
    @State private var showsDrinkTicket = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.appReduceMotion) private var appReduceMotion

    init(store: FreeRunStore, onCollapse: @escaping () -> Void, onComplete: @escaping (FreeRunSession) -> Void) {
        _store = State(initialValue: store)
        self.onCollapse = onCollapse
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            if store.session.endedAt != nil {
                FreeRunSummaryView(session: store.session) { onComplete(store.session) }
            } else {
                runningContent
                    .toolbar(.hidden, for: .navigationBar)
                    .confirmationDialog("結束這次路跑？", isPresented: $confirmEnd, titleVisibility: .visible) {
                        Button("結束並查看摘要", role: .destructive) { store.finish() }
                        Button("繼續路跑", role: .cancel) {}
                    }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.accentOnDark)
        .interactiveDismissDisabled()
        .sensoryFeedback(.impact(weight: .medium), trigger: store.session.hasArrived) { _, new in new }
        .sensoryFeedback(.success, trigger: store.feedbackCount)
        .onChange(of: store.session.hasArrived) { _, arrived in
            if arrived {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded = true }
            }
        }
        .onChange(of: store.feedbackCount) { _, _ in
            if let name = store.lastRecordedName {
                AccessibilityNotification.Announcement("已喝 \(store.session.uniqueBarCount) 家，已記錄：\(name)").post()
            }
        }
        .onChange(of: store.drinkFeedback?.showsTicket) { _, showsTicket in
            showsDrinkTicket = showsTicket == true
        }
        .sheet(isPresented: $showsDrinkTicket) {
            FreeRunDrinkTicketSheet(store: store)
        }
    }

    private var runningContent: some View {
        GeometryReader { geometry in
            if dynamicTypeSize.isAccessibilitySize || geometry.size.height < 600 {
                ScrollView {
                    runningLayout(maximumHeight: geometry.size.height * 0.6, accessible: true)
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    primaryActions.padding(18).background(AppTheme.surface)
                }
            } else {
                runningLayout(maximumHeight: geometry.size.height * 0.27, accessible: false)
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .background(AppTheme.background)
        .overlay {
            if let feedback = store.drinkFeedback {
                FreeRunCelebrationView(elapsed: feedback.elapsed)
                    .id(feedback.id)
            }
        }
        .animation(AppMotion.resolved(AppMotion.reveal, reduceMotion: reduceMotion || appReduceMotion), value: store.session.activeBarID)
        .sheet(isPresented: $showsSafeRide) { SafeRideSheet() }
        .sheet(isPresented: $showsNearbyBars) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("附近酒吧").font(.title2.bold())
                        Spacer()
                        Button("關閉") { showsNearbyBars = false }
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    nearbyBars
                }
                .padding(24)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
        }
    }

    private func runningLayout(maximumHeight: CGFloat, accessible: Bool) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button("收合路跑，繼續在 App 中使用", systemImage: "chevron.down", action: onCollapse)
                    .labelStyle(.iconOnly).buttonStyle(FreeRunMapButtonStyle())
                Text("示範：朋友位置為模擬資料")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            FreeRunMapView(session: store.session, friends: store.friends, now: store.now,
                           heatSegments: store.heatSegments, heading: store.heading,
                           attributions: store.mapAttributions)
                .frame(minHeight: accessible ? 220 : 70, maxHeight: accessible ? 220 : .infinity)
            FreeRunLiveMetricsCard(session: store.session, now: store.now, status: gpsStatus,
                                   isExpanded: panelExpanded) {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded.toggle() }
            }
            .padding(.horizontal, 14)
            bottomPanel(maximumHeight: maximumHeight, includesActions: !accessible)
        }
    }

    private var gpsStatus: String {
        if store.session.isPaused { return "已暫停" }
        if store.session.isDemo { return "示範模式" }
        if store.status == .denied { return "定位未授權" }
        if store.status == .unavailable { return "定位暫時不可用" }
        if store.session.hasAccurateLocation { return "GPS 已連線" }
        return store.status == .waiting ? "正在取得 GPS" : "定位精確度不足"
    }

    private func bottomPanel(maximumHeight: CGFloat, includesActions: Bool) -> some View {
        return VStack(spacing: 10) {
            Button {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded.toggle() }
            } label: {
                Capsule().fill(AppTheme.textTertiary).frame(width: 40, height: 5)
                    .frame(maxWidth: .infinity).frame(height: 44).contentShape(Rectangle())
            }
            .accessibilityLabel(panelExpanded ? "收合面板" : "展開面板")
            .simultaneousGesture(DragGesture(minimumDistance: 15).onEnded { value in
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) {
                    if abs(value.translation.height) > 25 { panelExpanded = value.translation.height < 0 }
                }
            })
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    nextStopCard
                    if let name = store.lastRecordedName {
                        Label("已記錄：\(name)", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(AppTheme.success)
                    }
                    if panelExpanded {
                        DisclosureGroup {
                            locationNotice
                            if store.session.isDemo {
                                Text("首站 3 秒、之後每站 5 秒。抵達後等你喝酒；非實際步行路線。")
                                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                            }
                            if let error = store.heatmapError { Text(error).font(.footnote) }
                        } label: {
                            Text("定位與示範設定")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .font(.subheadline)
                        .tint(AppTheme.textSecondary)
                        .buttonStyle(FreeRunActionButtonStyle())
                    }
                }
            }
            .frame(maxHeight: panelExpanded ? maximumHeight : 100)
            .scrollBounceBehavior(.basedOnSize)
            if panelExpanded {
                toolActions
                Text("飲酒後請勿騎車開車")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if includesActions { primaryActions }
        }
        .padding(.horizontal, 18).padding(.bottom, 12)
        .background(AppTheme.surface, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
    }

    private var primaryActions: some View {
        actionLayout {
            Button("結束", role: .destructive) { confirmEnd = true }
                .buttonStyle(FreeRunActionButtonStyle())
                .accessibilityHint("確認後結束路跑並查看摘要")
            Button(action: store.togglePause) {
                Label(store.session.isPaused ? "繼續" : "暫停",
                      systemImage: store.session.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(FreeRunActionButtonStyle(prominent: true))
        }
    }

    private var actionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
    }

    private var toolActions: some View {
        actionLayout {
            Button("附近酒吧", systemImage: "list.bullet") { showsNearbyBars = true }
            Button("安全回家", systemImage: "car.side.fill") { showsSafeRide = true }
                .accessibilityHint("開啟代駕、計程車與示範叫車選單")
        }
        .buttonStyle(FreeRunActionButtonStyle())
    }

    @ViewBuilder private var nextStopCard: some View {
        if let bar = store.session.activeBar {
            arrivalCard(bar).id(bar.id)
                .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion || appReduceMotion))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text(store.session.nearby.isEmpty ? "下一站 · 等待定位" : "今晚的酒吧都去過了").font(.headline)
                if store.session.nearby.isEmpty {
                    Text("取得準確位置後，會推薦最近的一間酒吧。")
                        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("可按下方結束，查看這次路跑摘要。")
                        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var locationNotice: some View {
        if let error = store.dataError {
            Text(error).font(.footnote).foregroundStyle(AppTheme.danger)
            Button("重新讀取") { store.start() }
        } else if store.status == .denied {
            Text("請允許 App 使用期間的定位，才能計算距離與辨識附近酒吧。也可以關閉後改用示範模式。")
                .font(.subheadline)
            Button("前往設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            .buttonStyle(FreeRunActionButtonStyle())
        } else if store.status == .unavailable {
            Text("暫時無法定位，請確認定位服務已開啟。")
                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
            Button("重試定位") { store.start() }
        } else if !store.session.hasAccurateLocation {
            Text(store.status == .waiting ? "正在取得位置…" : "定位精確度不足")
                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func arrivalCard(_ bar: FreeRunNearbyBar) -> some View {
        let canRecord = !store.session.isPaused && store.session.hasAccurateLocation && store.session.hasArrived && (store.drinkFeedback == nil || !store.session.isDemo)
        let remaining = max(0, Int(ceil(bar.distance - FreeRunRules.arrivalMeters)))
        let unavailableReason = store.session.isDemo && store.drinkFeedback != nil ? "正在完成喝酒紀錄" : store.session.isPaused ? "已暫停，繼續後才能喝酒" : !store.session.hasAccurateLocation ? "定位精確度不足" :
            (canRecord ? "" : "再走 \(remaining) m 才能喝酒")
        return VStack(alignment: .leading, spacing: 10) {
            actionLayout {
                Label(canRecord ? "下一站 · 已抵達" : "下一站", systemImage: canRecord ? "checkmark.circle.fill" : "wineglass.fill")
                    .font(.subheadline).foregroundStyle(AppTheme.accentOnDark)
                if store.session.hasAccurateLocation {
                    Text("約 \(Int(bar.distance.rounded())) m · \(NextBarRecommender.walkingMinutes(for: bar.distance)) 分")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            Text(bar.place.name).font(.headline)
            if panelExpanded {
                Button("喝酒") { store.record(using: passes) }
                    .buttonStyle(FreeRunActionButtonStyle(prominent: true))
                    .disabled(!canRecord)
                    .accessibilityHint(canRecord ? "記錄這間酒吧並推薦下一間，不會付款" : unavailableReason)
                if !canRecord {
                    Text(unavailableReason).font(.footnote).foregroundStyle(AppTheme.textSecondary)
                }
                Text("距離與時間為直線估算，請依實際道路行走。喝酒只記錄，不會付款。")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                if let alternative = store.session.nearby.first(where: {
                    $0.id != bar.id && $0.distance <= FreeRunRules.arrivalMeters && store.session.canRecord($0.id, at: store.now)
                }), store.session.hasAccurateLocation {
                    Button("你在 \(alternative.place.name) 附近，改去這間") { store.selectBar(alternative.id) }
                        .buttonStyle(FreeRunActionButtonStyle())
                        .disabled(store.session.isPaused)
                }
            }
        }
        .padding(16)
        .appGradientCard()
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
            .strokeBorder(AppTheme.accentOnDark.opacity(canRecord ? 0.9 : 0.4), lineWidth: canRecord ? 2 : 1)
            .allowsHitTesting(false))
        .animation(AppMotion.resolved(AppMotion.tap, reduceMotion: reduceMotion || appReduceMotion), value: canRecord)
    }

    private var nearbyBars: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("附近酒吧").font(.headline)
            if store.session.nearby.isEmpty {
                Text("取得位置後會顯示附近酒吧與距離。")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            }
            ForEach(Array(store.session.nearby.prefix(5))) { bar in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bar.place.name)
                        Text("約 \(Int(bar.distance.rounded())) 公尺")
                            .font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if store.session.canRecord(bar.id, at: store.now) {
                        Button(bar.id == store.session.activeBarID ? "下一站" : "改去這間") {
                            store.selectBar(bar.id)
                            showsNearbyBars = false
                        }
                            .buttonStyle(FreeRunActionButtonStyle())
                            .accessibilityLabel("將 \(bar.place.name) 設為下一站")
                            .disabled(store.session.isPaused || !store.session.hasAccurateLocation)
                    } else {
                        Label("已喝過", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(AppTheme.accentOnDark)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
