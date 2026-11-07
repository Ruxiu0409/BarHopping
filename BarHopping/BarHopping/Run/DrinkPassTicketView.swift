import SwiftUI

struct DrinkPassTicketView: View {
    let purchase: DrinkPassPurchase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("示範購買成功", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("\(purchase.option.name) × \(purchase.quantity)")
                .font(.headline)
            Text("共 \(purchase.totalCups) 杯・示範金額 NT$ \(purchase.totalPrice)")
            Text(purchase.option.validity)
                .font(.footnote)
            Image(systemName: "qrcode")
                .font(.system(size: 100))
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            Text("示範圖碼，無法掃描兌換")
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
            Text("票號：\(purchase.ticketNumber)")
                .font(.caption.monospaced())
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            Text("未收取款項，無實際效力。紀錄只保留在本次 App 使用期間。")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}
