import SwiftUI

struct AppLaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reducesMotion
    @State private var hasFinishedIntro = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if hasFinishedIntro || reducesMotion {
                ContentView()
            } else {
                LaunchIntroView(onFinish: finishIntro)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: reducesMotion, initial: true) { _, enabled in
            if enabled {
                hasFinishedIntro = true
            }
        }
    }

    private func finishIntro() {
        guard !hasFinishedIntro else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            hasFinishedIntro = true
        }
    }
}
