import SwiftUI

struct FreeRunView: View {
    let onCollapse: () -> Void
    let onComplete: (FreeRunSession) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var store: FreeRunStore
    @State private var confirmEnd = false
    @State private var showsNearbyBars = false
    @State private var panelExpanded = false
    @State private var panelHeight: CGFloat = 380
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
        .onChange(of: store.feedbackCount) { _, _ in
            if let name = store.lastRecordedName {
                AccessibilityNotification.Announcement("已記錄：\(name)").post()
            }
        }
    }

    private var runningContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                FreeRunMapView(session: store.session, friends: store.friends, now: store.now,
                               heatSegments: store.heatSegments, heading: store.heading, bottomInset: panelHeight,
                               attributions: store.mapAttributions)
                    .ignoresSafeArea()
                VStack(spacing: 10) {
                    FreeRunLiveMetricsCard(session: store.session, now: store.now, status: gpsStatus) {
                        withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded.toggle() }
                    }
                    .padding(.horizontal, 14)
                    bottomPanel(maximumHeight: geometry.size.height * 0.5)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { panelHeight = $0 }
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Button("收合路跑，繼續在 App 中使用", systemImage: "chevron.down", action: onCollapse)
                        .labelStyle(.iconOnly).buttonStyle(FreeRunMapButtonStyle())
                    Text("示範：朋友位置為模擬資料")
                        .font(.caption2).foregroundStyle(AppTheme.accentOnDark)
                        .padding(8).background(.ultraThinMaterial, in: Capsule())
                }
                .padding(14)
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .background(AppTheme.background)
        .animation(AppMotion.resolved(AppMotion.reveal, reduceMotion: reduceMotion || appReduceMotion), value: store.session.activeBarID)
        .sheet(isPresented: $showsNearbyBars) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("附近酒吧").font(.title2.bold())
                        Spacer()
                        Button("關閉") { showsNearbyBars = false }
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

    private var gpsStatus: String {
        if store.session.isPaused { return "已暫停" }
        if store.session.isDemo { return "示範模式" }
        if store.status == .denied { return "定位未授權" }
        if store.status == .unavailable { return "定位暫時不可用" }
        if store.session.hasAccurateLocation { return "GPS 已連線" }
        return store.status == .waiting ? "正在取得 GPS" : "定位精確度不足"
    }

    private func bottomPanel(maximumHeight: CGFloat) -> some View {
        @Bindable var binding = store
        return VStack(spacing: 10) {
            Button {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded.toggle() }
            } label: {
                Capsule().fill(AppTheme.textTertiary).frame(width: 40, height: 5)
                    .frame(maxWidth: .infinity).frame(height: 22).contentShape(Rectangle())
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
                        locationNotice
                        Text("已停留 \(store.session.uniqueBarCount) 間酒吧").font(.headline)
                        if store.session.isDemo {
                            Toggle("示範定位 · 加速 ×5", isOn: $binding.accelerated)
                            Text("假定位直線前往下一站，抵達後等你買酒；非實際步行路線。")
                                .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                        }
                        if let error = store.heatmapError { Text(error).font(.footnote) }
                        Button("附近酒吧", systemImage: "list.bullet") { showsNearbyBars = true }
                            .buttonStyle(.bordered)
                        Text("飲酒後請勿騎車開車").font(.footnote).foregroundStyle(AppTheme.textSecondary)
                        SafeRideButton()
                        Button("結束路跑", role: .destructive) { confirmEnd = true }.buttonStyle(.bordered)
                    }
                }
            }
            .frame(maxHeight: panelExpanded ? maximumHeight : 150)
            .scrollBounceBehavior(.basedOnSize)
            HStack(spacing: 12) {
                Button {
                    store.togglePause()
                } label: {
                    Label(store.session.isPaused ? "繼續" : "暫停", systemImage: store.session.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3.bold()).frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent).buttonBorderShape(.capsule).tint(AppTheme.accent)
                if store.session.isPaused {
                    Button("結束") { confirmEnd = true }
                        .font(.headline).frame(minHeight: 52).padding(.horizontal, 16)
                        .buttonStyle(.bordered).buttonBorderShape(.capsule)
                }
            }
        }
        .padding(.horizontal, 18).padding(.bottom, 12)
        .background(AppTheme.surface, in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24))
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
                    Button("等待定位才能買酒") {}.disabled(true)
                } else {
                    Button("結束路跑") { confirmEnd = true }.buttonStyle(.borderedProminent)
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
            .buttonStyle(.bordered)
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
        let canRecord = !store.session.isPaused && store.session.hasAccurateLocation && store.session.hasArrived
        let remaining = max(0, Int(ceil(bar.distance - FreeRunRules.arrivalMeters)))
        let buttonTitle = store.session.isPaused ? "已暫停，繼續後才能買酒" : !store.session.hasAccurateLocation ? "定位精確度不足" :
            (canRecord ? "買酒" : "再走 \(remaining) m 才能買酒")
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(canRecord ? "下一站 · 已抵達" : "下一站", systemImage: canRecord ? "checkmark.circle.fill" : "wineglass.fill")
                    .font(.subheadline).foregroundStyle(AppTheme.accentOnDark)
                Spacer()
                if store.session.hasAccurateLocation {
                    Text("約 \(Int(bar.distance.rounded())) m · \(NextBarRecommender.walkingMinutes(for: bar.distance)) 分")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
            Text(bar.place.name).font(.headline)
            Button(buttonTitle) { store.record() }
                .font(.headline)
                .foregroundStyle(canRecord ? .white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(canRecord ? AppTheme.accent : AppTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                .disabled(!canRecord)
                .accessibilityHint(canRecord ? "記錄在這間酒吧停留，之後推薦下一間，不會付款" :
                    (store.session.isPaused ? "路跑已暫停，請先按繼續" : store.session.hasAccurateLocation ? "須進入下一站四十公尺內才能買酒" : "需要五十公尺以內的定位精確度"))
            if panelExpanded {
                Text("距離與時間為直線估算，請依實際道路行走。買酒只記錄，不會付款。")
                    .font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            if let alternative = store.session.nearby.first(where: {
                $0.id != bar.id && $0.distance <= FreeRunRules.arrivalMeters && store.session.canRecord($0.id, at: store.now)
            }), store.session.hasAccurateLocation {
                Button("你在 \(alternative.place.name) 附近，改去這間") { store.selectBar(alternative.id) }
                    .font(.caption).foregroundStyle(AppTheme.accentOnDark)
            }
        }
        .padding(16)
        .appGradientCard()
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
            .strokeBorder(AppTheme.accentOnDark.opacity(canRecord ? 0.9 : 0.4), lineWidth: canRecord ? 2 : 1)
            .allowsHitTesting(false))
        .animation(AppMotion.resolved(AppMotion.tap, reduceMotion: reduceMotion), value: canRecord)
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
                            .buttonStyle(.bordered)
                            .accessibilityLabel("將 \(bar.place.name) 設為下一站")
                            .disabled(store.session.isPaused || !store.session.hasAccurateLocation)
                    } else {
                        Label("已買過", systemImage: "checkmark.circle.fill")
                            .font(.caption).foregroundStyle(AppTheme.accentOnDark)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
