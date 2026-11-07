import SwiftUI

struct DrinkPassBanner: View {
    let event: DrinkPassEvent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                DrinkPassKeyVisual()
                bannerContent
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface.opacity(0.75))
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGradientCard()
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("開啟示範酒票介紹、方案與虛構合作店家")
    }

    private var bannerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Label("酒票推薦", systemImage: "ticket.fill")
                    .font(.subheadline.bold())
                Spacer()
                Text("廣告")
                    .font(.caption)
            }
            Text(event.name)
                .font(.title2.bold())
            Text(event.tagline)
                .font(.subheadline)
            Text("NT$ \(event.startingPrice) 起")
                .font(.headline)
            Label("看酒票", systemImage: "arrow.right")
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppTheme.accent, in: Capsule())
            Text("示範資料，非真實活動")
                .font(.footnote.weight(.semibold))
        }
    }
}
