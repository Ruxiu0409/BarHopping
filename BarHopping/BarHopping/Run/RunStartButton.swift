import SwiftUI

struct RunStartButton: View {
    let hasStops: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var diameter: CGFloat = 160
    @State private var feedbackTrigger = false

    var body: some View {
        Button {
            feedbackTrigger.toggle()
            action()
        } label: {
            Text("開始")
                .font(.largeTitle.bold())
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(24)
                .frame(width: min(diameter, 260), height: min(diameter, 260))
                .background(AppTheme.accent, in: Circle())
                .overlay {
                    Circle().strokeBorder(AppTheme.textPrimary.opacity(0.25), lineWidth: 1.5)
                }
                .contentShape(Circle())
                .shadow(color: AppTheme.accent.opacity(0.28), radius: 16, y: 4)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .medium), trigger: feedbackTrigger)
        .accessibilityLabel("開始路跑")
        .accessibilityHint(hasStops ? "前往地圖並顯示目前路線" : "查看規劃路線提示")
    }
}
