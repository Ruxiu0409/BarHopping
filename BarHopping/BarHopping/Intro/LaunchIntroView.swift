import GlassIntroKit
import SwiftUI

struct LaunchIntroView: View {
    let onFinish: () -> Void

    private var intro: GlassIntro {
        GlassIntro(
            appName: "逢酒必喝 BarHopping",
            mark: .custom(
                bodyDiameterRatio: 0.76,
                outline: { rect, _ in
                    let side = min(rect.width, rect.height) * 0.76
                    let iconRect = CGRect(
                        x: rect.midX - side / 2,
                        y: rect.midY - side / 2,
                        width: side,
                        height: side
                    )
                    return RoundedRectangle(cornerRadius: side * 0.2237, style: .continuous)
                        .path(in: iconRect)
                },
                view: { LaunchAppIconView() }
            ),
            pages: [],
            finale: [],
            tint: AppTheme.accent,
            background: AppTheme.background,
            welcome: .never,
            opening: .mark
        )
    }

    var body: some View {
        AppTheme.background
            .ignoresSafeArea()
            .glassIntro(intro)
            .overlay(alignment: .bottom) {
                VStack(spacing: 12) {
                    VStack(spacing: 4) {
                        Text("逢酒必喝")
                            .font(.largeTitle.bold())
                        Text("BarHopping")
                            .font(.title3.weight(.medium))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("逢酒必喝 BarHopping")
                    Text("串起城市裡的微醺夜晚")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.accentOnDark)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 64)
            }
            .overlay(alignment: .topTrailing) {
                Button("跳過", action: onFinish)
                    .font(.body)
                    .foregroundStyle(AppTheme.accentOnDark)
                    .padding(16)
                    .contentShape(.rect)
                    .padding(8)
            }
            .accessibilityAction(.escape, onFinish)
            .task {
                // The kit has no duration control; removing this overlay cancels its launch task.
                do {
                    try await Task.sleep(for: .milliseconds(1650))
                } catch {
                    return
                }
                onFinish()
            }
    }
}
