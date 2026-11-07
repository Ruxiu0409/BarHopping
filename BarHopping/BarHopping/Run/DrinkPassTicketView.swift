import SwiftUI

struct DrinkPassTicketView: View {
    let purchase: DrinkPassPurchase
    @Environment(DrinkPassStore.self) private var store

    private var currentPurchase: DrinkPassPurchase {
        store.purchases.first { $0.id == purchase.id } ?? purchase
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentPurchase.eventName).font(.title2.bold())
            Label("已購買", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
            Text("\(currentPurchase.option.name) × \(currentPurchase.quantity)")
                .font(.headline)
            Text("共 \(currentPurchase.totalCups) 杯・NT$ \(currentPurchase.totalPrice)")
            Text(currentPurchase.option.validity)
                .font(.footnote)
            Text("剩餘 \(currentPurchase.remainingCups) 杯")
                .font(.headline).monospacedDigit()
            Text("票號：\(currentPurchase.ticketNumber)")
                .font(.caption.monospaced())
                .textSelection(.enabled)
            PassQRCodeView(payload: DrinkPassArtwork.qrCodePayload(for: currentPurchase))
                .frame(maxWidth: .infinity)
                .textSelection(.enabled)
            Text("QR Code 內容：\(DrinkPassArtwork.qrCodePayload(for: currentPurchase))，酒票僅供示範")
                .font(.footnote.bold())
                .frame(maxWidth: .infinity)
            Text("未收取款項，無實際效力。紀錄只保留在本次 App 使用期間。")
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 8)
    }
}
