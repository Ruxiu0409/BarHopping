import SwiftUI
import Foundation

struct SafeRideDemoView: View {
    enum Stage: Equatable {
        case estimate, matching, matched, cancelled
    }

    let pickup: Waypoint?
    let destinationName: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var statusFocused: Bool
    @State private var destination = SafeRideDemoEstimate.destinations[0]
    @State private var stage: Stage

    init(pickup: Waypoint?, destinationName: String, initialStage: Stage = .estimate) {
        self.pickup = pickup
        self.destinationName = destinationName
        _stage = State(initialValue: initialStage)
    }

    private var estimate: SafeRideDemoEstimate? {
        SafeRideDemoEstimate(pickup: pickup, destination: destination)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("示範模式，未實際叫車", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.accentOnDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppTheme.accentSoft, in: RoundedRectangle(cornerRadius: 14))
                Text("此流程不會聯絡服務商、派遣司機或收費。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                switch stage {
                case .estimate: estimateContent
                case .matching: matchingContent
                case .matched: driverContent
                case .cancelled: cancelledContent
                }
                if dynamicTypeSize.isAccessibilitySize {
                    SafeRideSafetyFooter()
                }
            }
            .padding(16)
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .navigationTitle("示範叫代駕")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: stage) {
            guard stage == .matching else { return }
            do {
                try await Task.sleep(for: .milliseconds(2_500))
                try Task.checkCancellation()
                stage = .matched
            } catch { return }
        }
        .onChange(of: stage) { _, _ in statusFocused = true }
    }

    private var estimateContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("示範估價")
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            tripSummary
            VStack(alignment: .leading, spacing: 8) {
                Text("選擇台中範例目的地").font(.headline)
                Picker("範例目的地", selection: $destination) {
                    ForEach(SafeRideDemoEstimate.destinations) { place in
                        Text(place.name).tag(place)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.textPrimary)
                .frame(minHeight: 44)
                Text("僅使用選定的範例座標試算，未將輸入文字轉成地址。")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            quoteCard
            Button("送出示範代駕需求", systemImage: "steeringwheel") { stage = .matching }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppTheme.accent)
                .accessibilityHint("僅模擬配對，不會實際叫車或收費")
        }
    }

    private var tripSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(pickup == nil ? "上車：未取得目前位置" : "上車：目前位置", systemImage: "location.fill")
            let note = destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty {
                Text("目的地文字備註：\(note)")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            Text("估價終點：\(destination.name)")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appGlassCard()
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let estimate {
                Text("NT$\(estimate.amount)")
                    .font(.largeTitle.bold())
                    .accessibilityLabel("示範估價，新台幣 \(estimate.amount) 元")
                Text("起訖直線距離約 \(Fmt.distance(estimate.distanceMeters))")
                Text("示範算法：起步 NT$350 ＋ 每公里 NT$30，總額無條件進位至元。")
                    .font(.caption)
            } else {
                Text("無法估價（未取得位置）")
                    .font(.headline)
                Text("仍可體驗模擬配對，或返回上一頁重新定位。")
                    .font(.subheadline)
            }
            Text("示範估價，非實際報價")
                .font(.headline)
                .foregroundStyle(AppTheme.accentOnDark)
            Text("直線距離不是行車路線；未計入路況、等候或其他費用。")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appGlassCard()
    }

    private var matchingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView("配對司機中…")
                .font(.title3.bold())
                .tint(AppTheme.accentOnDark)
                .accessibilityFocused($statusFocused)
            Text("約 2–3 秒後顯示虛構司機，未送出任何真實訂單。")
                .foregroundStyle(AppTheme.textSecondary)
            cancelButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appGlassCard()
    }

    private var driverContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("已配對示範司機", systemImage: "person.crop.circle.badge.checkmark")
                .font(.title2.bold())
                .accessibilityFocused($statusFocused)
            Text("阿安（虛構司機）").font(.title3.bold())
            Label("評分 4.9／5（示範）", systemImage: "star.fill")
            Text("車牌：DEMO-＊＊＊（虛構、已遮蔽）")
            Label("預計 6 分鐘抵達（示範）", systemImage: "clock")
            Text("不會有司機前來。若需要返家，請返回選擇外部叫車服務。")
                .foregroundStyle(AppTheme.textSecondary)
            tripSummary
            quoteCard
            cancelButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appGlassCard()
    }

    private var cancelledContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("示範需求已取消", systemImage: "checkmark.circle")
                .font(.title2.bold())
                .accessibilityFocused($statusFocused)
            Text("未實際叫車，也沒有任何費用。")
                .foregroundStyle(AppTheme.textSecondary)
            Button("重新體驗示範", systemImage: "arrow.clockwise") { stage = .estimate }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppTheme.accent)
        }
    }

    private var cancelButton: some View {
        Button("取消示範需求", role: .destructive) { stage = .cancelled }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(AppTheme.danger)
    }
}

#Preview("示範估價") {
    NavigationStack {
        SafeRideDemoView(pickup: .custom(name: "目前位置", at: Coordinate(latitude: 24.1511, longitude: 120.6639)),
                         destinationName: "家")
    }
    .preferredColorScheme(.dark)
}

#Preview("示範司機・小螢幕") {
    NavigationStack {
        SafeRideDemoView(pickup: nil, destinationName: "", initialStage: .matched)
    }
    .preferredColorScheme(.dark)
}
