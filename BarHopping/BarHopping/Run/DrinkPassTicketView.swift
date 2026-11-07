import SwiftUI

struct DrinkPassTicketView: View {
    let purchase: DrinkPassPurchase

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(purchase.eventName).font(.title2.bold())
            Label("示範購買成功", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("\(purchase.option.name) × \(purchase.quantity)")
                .font(.headline)
            Text("共 \(purchase.totalCups) 杯・示範金額 NT$ \(purchase.totalPrice)")
            Text(purchase.option.validity)
                .font(.footnote)
            PassQRCodeView(payload: purchase.ticketNumber)
                .frame(maxWidth: .infinity)
                .textSelection(.enabled)
            Text("示範票號 QR Code，無法兌換酒款")
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
            Text("未收取款項，無實際效力。紀錄只保留在本次 App 使用期間。")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}
