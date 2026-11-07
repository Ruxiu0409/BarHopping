import SwiftUI

private struct AppLoadingPlaceholderModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    @Environment(\.scenePhase) private var scenePhase
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .redacted(reason: isLoading ? .placeholder : [])
            .overlay {
                if isLoading && !reduceMotion && scenePhase == .active {
                    // 時間線由 SwiftUI 管理生命週期；離開前景或移除 placeholder 即停止更新。
                    TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                        GeometryReader { geometry in
                            let phase = timeline.date.timeIntervalSinceReferenceDate
                                .truncatingRemainder(dividingBy: 1.8) / 1.8
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.12), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: geometry.size.width * 0.6)
                            .offset(x: geometry.size.width * (phase * 1.6 - 0.6))
                        }
                    }
                    .mask(content.redacted(reason: .placeholder))
                    .clipped()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .disabled(isLoading)
            .accessibilityHidden(isLoading)
    }
}

extension View {
    /// 只替真正等待資料的非互動卡片使用，保留固定版面；不要對整頁或長清單同時 shimmer。
    /// 請在外層提供可被 VoiceOver 讀取的 ProgressView("載入中")，完成後移除此效果。
    /// 減少動態效果保留靜態 redacted；停止載入或離開前景後不再建立時間線。
    func appLoadingPlaceholder(_ isLoading: Bool) -> some View {
        modifier(AppLoadingPlaceholderModifier(isLoading: isLoading))
    }
}
