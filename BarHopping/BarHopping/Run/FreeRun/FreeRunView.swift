import SwiftUI

struct FreeRunView: View {
    let onComplete: (FreeRunSession) -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var store: FreeRunStore
    @State private var confirmEnd = false

    init(isDemo: Bool, onComplete: @escaping (FreeRunSession) -> Void) {
        _store = State(initialValue: FreeRunStore(isDemo: isDemo))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            if store.session.endedAt != nil {
                FreeRunSummaryView(session: store.session) { onComplete(store.session) }
            } else {
                runningContent
                    .navigationTitle("自由路跑")
                    .navigationBarTitleDisplayMode(.inline)
                    .safeAreaInset(edge: .bottom) {
                        Button("結束") { confirmEnd = true }
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.accent)
                            .padding()
                            .background(AppTheme.background)
                    }
                    .confirmationDialog("結束這次路跑？", isPresented: $confirmEnd, titleVisibility: .visible) {
                        Button("結束並查看摘要", role: .destructive) { store.finish() }
                        Button("繼續路跑", role: .cancel) {}
                    }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.accentOnDark)
        .interactiveDismissDisabled()
        .task {
            if scenePhase == .active { store.start() }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { break }
                store.tick()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.start() } else { store.suspend() }
        }
        .onDisappear { store.suspend() }
        .sensoryFeedback(.impact(weight: .medium), trigger: store.session.activeBarID) { _, new in new != nil }
        .sensoryFeedback(.success, trigger: store.feedbackCount)
        .onChange(of: store.feedbackCount) { _, _ in
            if let name = store.lastRecordedName {
                AccessibilityNotification.Announcement("已記錄：\(name)").post()
            }
        }
    }

    private var runningContent: some View {
        @Bindable var binding = store
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if store.session.isDemo {
                    Label("示範模式 · 審計新村", systemImage: "play.circle.fill")
                        .font(.headline).foregroundStyle(AppTheme.accentOnDark)
                    Toggle("加速 ×5", isOn: $binding.accelerated)
                        .tint(AppTheme.accent)
                    Text("假定位沿內附路徑前進；買酒只記錄停留，不會付款。")
                        .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                    if store.status == .demoFinished {
                        Text("示範已到終點，可記錄附近酒吧或結束查看摘要。")
                            .font(.footnote).foregroundStyle(AppTheme.accentOnDark)
                    }
                }
                FreeRunMetricsView(session: store.session, now: store.now)
                locationNotice
                if let bar = store.session.activeBar {
                    arrivalCard(bar)
                        .id(bar.id)
                        .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion))
                }
                if let name = store.lastRecordedName {
                    Label("已記錄：\(name)", systemImage: "checkmark.circle.fill")
                        .font(.subheadline).foregroundStyle(AppTheme.success)
                }
                nearbyBars
                Text("飲酒後請勿騎車開車")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                SafeRideButton()
            }
            .padding(20)
            .animation(AppMotion.resolved(AppMotion.reveal, reduceMotion: reduceMotion), value: store.session.activeBarID)
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
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
        let canRecord = store.session.canRecord(bar.id, at: store.now)
        return VStack(alignment: .leading, spacing: 12) {
            Label("附近有酒吧", systemImage: "wineglass.fill")
                .font(.subheadline).foregroundStyle(AppTheme.accentOnDark)
            Text(bar.place.name).font(.title2.bold())
            Text("距離約 \(Int(bar.distance.rounded())) 公尺")
                .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            Button(canRecord ? "買酒" : "已記錄") { store.record() }
                .font(.title3.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 12))
                .disabled(!canRecord)
                .accessibilityHint(canRecord ? "記錄在這間酒吧停留，不會付款" : "同一間酒吧十分鐘內不重複記錄")
            Text(canRecord ? "只記錄停留，不會付款。" : "10 分鐘內不重複記錄。")
                .font(.caption).foregroundStyle(AppTheme.textSecondary)
        }
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius).strokeBorder(AppTheme.accentOnDark.opacity(0.5)))
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
                    if bar.distance <= FreeRunRules.arrivalMeters {
                        Button("查看") { store.selectBar(bar.id) }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("查看 \(bar.place.name)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
