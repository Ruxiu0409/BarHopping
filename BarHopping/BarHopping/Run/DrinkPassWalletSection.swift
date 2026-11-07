import SwiftUI

struct DrinkPassWalletSection: View {
    @Environment(DrinkPassStore.self) private var store
    @State private var selectedPurchase: DrinkPassPurchase?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的酒票").font(.title2.bold())
            if store.purchases.isEmpty {
                Text("還沒有酒票，到首頁看看龍蛇酒雜")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
            } else {
                ForEach(store.purchases.reversed()) { purchase in
                    Button { selectedPurchase = purchase } label: {
                        DrinkPassWalletCard(purchase: purchase)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("開啟酒票與示範圖碼")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $selectedPurchase) { purchase in
            DrinkPassTicketDetailView(purchase: purchase)
        }
    }
}
