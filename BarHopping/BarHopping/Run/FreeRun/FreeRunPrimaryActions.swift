import SwiftUI

struct FreeRunPrimaryActions: View {
    let store: FreeRunStore
    @Binding var confirmEnd: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
        layout {
            Button("結束", role: .destructive) { confirmEnd = true }
                .buttonStyle(FreeRunActionButtonStyle())
                .accessibilityHint("確認後結束路跑並查看摘要")
            Button(action: store.togglePause) {
                Label(store.session.isPaused ? "繼續" : "暫停",
                      systemImage: store.session.isPaused ? "play.fill" : "pause.fill")
            }
            .buttonStyle(FreeRunActionButtonStyle(prominent: true))
        }
    }
}
