import SwiftUI
import Foundation

struct SafeRideSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var destinationName = ""
    @State private var showingDemo = false
    @State private var launcher = SafeRideLauncher()
    @State private var location = SafeRidePickupStore()
    @State private var locationRefresh = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    tripFields
                    ForEach(SafeRideProvider.Kind.allCases) { kind in
                        providerSection(kind)
                    }
                    demoEntry
                    if dynamicTypeSize.isAccessibilitySize {
                        SafeRideSafetyFooter()
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(AppTheme.background)
            .navigationTitle("安全回家")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showingDemo) {
                SafeRideDemoView(pickup: location.pickup, destinationName: destinationName)
            }
            .alert("確認撥打電話", isPresented: $launcher.showingPhoneConfirmation,
                   presenting: launcher.pendingCall) { call in
                Button("撥打 \(call.number)") { launcher.confirmPhoneCall(using: openURL) }
                Button("取消", role: .cancel) { }
            } message: { call in
                Text("即將撥打\(call.name)（\(call.number)）。是否繼續？")
            }
            .alert("無法開啟服務", isPresented: $launcher.showingError) { } message: {
                Text(launcher.errorMessage)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !dynamicTypeSize.isAccessibilitySize {
                SafeRideSafetyFooter()
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accentOnDark)
        .preferredColorScheme(.dark)
        .task(id: locationRefresh) { await location.request() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active && location.hasFailed { locationRefresh += 1 }
        }
    }

    private var tripFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("今晚，平安到家", systemImage: "house.fill")
                .font(.title2.bold())
            VStack(alignment: .leading, spacing: 6) {
                Text("上車起點").font(.caption).foregroundStyle(AppTheme.textSecondary)
                pickupStatus
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("目的地（選填）").font(.caption).foregroundStyle(AppTheme.textSecondary)
                TextField("例如：家、飯店或地址", text: $destinationName, axis: .vertical)
                    .textContentType(.fullStreetAddress)
                    .submitLabel(.done)
                    .padding(12)
                    .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityLabel("目的地，選填")
                Text("文字目的地尚未定位。請在叫車服務內重新確認地址與報價；其他 App 的商店連結不會帶入行程。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .padding(16)
        .appGlassCard()
    }

    private func providerSection(_ kind: SafeRideProvider.Kind) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(kind.rawValue)
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            Text(kind == .designatedDriver ? "有開車來？請代駕幫您把車開回家。" : "沒開車來，搭車回家。")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
            ForEach(SafeRideProvider.all.filter { $0.kind == kind }) { provider in
                Button {
                    launcher.open(provider, pickup: location.pickup, destinationName: destinationName, using: openURL)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: provider.symbol)
                            .font(.title3)
                            .foregroundStyle(AppTheme.accentOnDark)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.accentSoft, in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(provider.name).font(.headline)
                            Text(provider.summary)
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(provider.openingMethod.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppTheme.accentOnDark)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.forward")
                            .foregroundStyle(AppTheme.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .appGlassCard()
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(provider.name)，\(provider.openingMethod.label)")
                .accessibilityHint(provider.summary)
            }
        }
    }

    private var demoEntry: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("App 內示範叫代駕", systemImage: "play.circle.fill") { showingDemo = true }
                .font(.headline)
                .buttonStyle(.borderedProminent).tint(AppTheme.accent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            Text("示範模式，未實際叫車。體驗估價與司機配對流程。")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    @ViewBuilder
    private var pickupStatus: some View {
        switch location.status {
        case .locating:
            ProgressView("正在取得你的位置…")
                .tint(AppTheme.accentOnDark)
        case .located(let coordinate):
            Label("目前位置", systemImage: "location.fill").font(.headline)
            Text(String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude))
                .font(.caption.monospacedDigit())
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityLabel("緯度 \(coordinate.latitude)，經度 \(coordinate.longitude)")
        case .failed:
            Label("目前位置尚未取得", systemImage: "location.slash")
                .font(.headline)
            Text(location.failureMessage)
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
            ViewThatFits(in: .horizontal) {
                HStack { locationActions }
                VStack(alignment: .leading) { locationActions }
            }
            .buttonStyle(.bordered)
        }
    }

    private var locationActions: some View {
        Group {
            Button("前往設定", systemImage: "gearshape") { launcher.openSettings(using: openURL) }
            Button("重新定位", systemImage: "location") { locationRefresh += 1 }
        }
        .frame(minHeight: 44)
    }
}

#Preview("安全回家・目前位置") {
    SafeRideSheet()
}

#Preview("安全回家・無起點・輔助字級") {
    SafeRideSheet()
        .environment(\.dynamicTypeSize, .accessibility3)
}
