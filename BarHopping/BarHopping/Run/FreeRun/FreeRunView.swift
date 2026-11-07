import SwiftUI

struct FreeRunView: View {
    let onCollapse: () -> Void
    let onComplete: (FreeRunSession) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            if store.hasEnded {
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
        .sensoryFeedback(.impact(weight: .medium), trigger: store.hasArrived) { _, new in new }
        .sensoryFeedback(.success, trigger: store.feedbackCount)
        .onChange(of: store.hasArrived) { _, arrived in
            if arrived {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded = true }
            }
        }
        .onChange(of: store.feedbackCount) { _, _ in
            if let name = store.lastRecordedName {
                AccessibilityNotification.Announcement("已喝 \(store.session.uniqueBarCount) 家，已記錄：\(name)").post()
            }
        }
        .onChange(of: store.feedbackShowsTicket) { _, showsTicket in
            showsDrinkTicket = showsTicket
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
                    FreeRunPrimaryActions(store: store, confirmEnd: $confirmEnd)
                        .padding(18).background(AppTheme.surface)
                }
            } else {
                runningLayout(maximumHeight: geometry.size.height * 0.27, accessible: false)
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .background(AppTheme.background)
        .overlay { FreeRunFeedbackOverlay(store: store) }
        .sheet(isPresented: $showsSafeRide) { SafeRideSheet() }
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
            FreeRunMapContainer(store: store)
                .frame(minHeight: accessible ? 220 : 70, maxHeight: accessible ? 220 : .infinity)
            FreeRunMetricsContainer(store: store, isExpanded: panelExpanded) {
                withAppAnimation(reduceMotion: reduceMotion || appReduceMotion) { panelExpanded.toggle() }
            }
            .padding(.horizontal, 14)
            panel(maximumHeight: maximumHeight, includesActions: !accessible)
        }
    }

    private func panel(maximumHeight: CGFloat, includesActions: Bool) -> some View {
        FreeRunPanelView(store: store, maximumHeight: maximumHeight, includesActions: includesActions,
                         panelExpanded: $panelExpanded, confirmEnd: $confirmEnd,
                         showsNearbyBars: $showsNearbyBars, showsSafeRide: $showsSafeRide)
    }
}
