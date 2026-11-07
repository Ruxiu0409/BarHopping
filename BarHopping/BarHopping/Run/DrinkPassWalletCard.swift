import SwiftUI

struct DrinkPassWalletCard: View {
    let purchase: DrinkPassPurchase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(DrinkPassArtwork.keyVisualImageName)
                    .resizable().scaledToFit()
                    .frame(width: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(purchase.eventName).font(.headline)
                    Text("\(purchase.option.name) × \(purchase.quantity) 張")
                        .font(.subheadline)
                }
            }
            Text("剩餘 \(purchase.remainingCups) 杯")
                .font(.subheadline.bold()).foregroundStyle(AppTheme.accentOnDark)
            Text("使用期限：\(purchase.option.validity)")
                .font(.caption).foregroundStyle(AppTheme.textSecondary)
            Text("票號：\(purchase.ticketNumber)")
                .font(.caption.monospaced()).foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Label("查看酒票", systemImage: "qrcode")
                .font(.subheadline.bold()).foregroundStyle(AppTheme.accentOnDark)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .foregroundStyle(AppTheme.textPrimary)
        .accessibilityElement(children: .combine)
    }
}
