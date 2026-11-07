import SwiftUI

private struct AppMotionPreview: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    @State private var expanded = false
    @State private var count = 0
    @State private var failure = 0
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("共用動畫").font(.title.bold())
                Button {
                    withAppAnimation(AppMotion.reveal, reduceMotion: reduceMotion) { expanded.toggle() }
                } label: {
                    Label(expanded ? "收合路線摘要" : "展開路線摘要", systemImage: "map")
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AppTheme.accent, in: .rect(cornerRadius: 16))
                }
                .buttonStyle(AppPressableButtonStyle())
                // 選取改變才回饋；不在畫面出現或一般按壓時震動。
                .sensoryFeedback(.selection, trigger: expanded)

                if expanded {
                    Text("步行串店路線已展開")
                        .padding().frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: .rect(cornerRadius: 16))
                        .appTransition(.insertionRemoval)
                }

                HStack {
                    Text("已儲存 \(count) 條").appNumericText(value: count)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .appSymbolBounce(trigger: count)
                        .accessibilityHidden(true)
                }
                Button("示範儲存成功") { count += 1 }
                    .buttonStyle(.bordered)
                    // 用完成事件計數，避免同一結果重繪就震動。
                    .sensoryFeedback(.success, trigger: count)
                Button("示範操作失敗") { failure += 1 }
                    .buttonStyle(.bordered)
                    .sensoryFeedback(.error, trigger: failure)
                if failure > 0 {
                    Text("示範錯誤，請重試").foregroundStyle(AppTheme.danger)
                        .appTransition()
                }
                Toggle("示範載入", isOn: $loading)
                Text("路線摘要與站點資訊")
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface, in: .rect(cornerRadius: 16))
                    .appLoadingPlaceholder(loading)
                if loading { ProgressView("載入中") }
                Text(reduceMotion ? "減少動態效果：開啟" : "減少動態效果：關閉")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            .padding()
            .appAnimation(value: failure)
        }
        .background(AppTheme.background)
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accentOnDark)
        .preferredColorScheme(.dark)
    }
}

#Preview("共用動畫") { AppMotionPreview() }

#Preview("共用動畫・減少動態效果") {
    AppMotionPreview().environment(\.appReduceMotion, true)
}
