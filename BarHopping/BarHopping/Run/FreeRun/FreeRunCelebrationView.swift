import SwiftUI

struct FreeRunCelebrationView: View {
    let elapsed: TimeInterval
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion
    @State private var startedAt = Date.now
    @State private var showsCheckmark = false

    var body: some View {
        if elapsed < FreeRunDemoScript.confettiSeconds {
            Group {
                if reduceMotion || appReduceMotion {
                    Label("已記錄", systemImage: "checkmark.circle.fill")
                        .font(.headline).padding(16)
                        .foregroundStyle(AppTheme.textPrimary)
                        .background(AppTheme.surface, in: Capsule())
                        .opacity(showsCheckmark ? 1 : 0)
                        .onAppear {
                            withAnimation(.easeIn(duration: 0.2)) { showsCheckmark = true }
                        }
                        .transition(.opacity)
                } else {
                    TimelineView(.animation) { timeline in
                        Canvas { context, size in
                            let progress = min(1, max(0, timeline.date.timeIntervalSince(startedAt) / FreeRunDemoScript.confettiSeconds))
                            let colors = [AppTheme.accent, AppTheme.accentOnDark,
                                          Color(red: 0.87, green: 0.64, blue: 0.80),
                                          Color(red: 0.89, green: 0.73, blue: 0.37)]
                            for index in 0..<48 {
                                let seed = Double(index)
                                let x = size.width * (0.5 + sin(seed * 2.4) * progress * 0.7)
                                let y = -24 + size.height * (progress * progress * 1.2) - sin(seed) * 90 * progress
                                var particle = context
                                particle.opacity = min(1, (1 - progress) * 3)
                                particle.translateBy(x: x, y: y)
                                particle.rotate(by: .degrees(seed * 37 + progress * 540))
                                particle.fill(Path(CGRect(x: -3, y: -6, width: 6, height: 12)),
                                              with: .color(colors[index % colors.count]))
                            }
                        }
                    }
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
