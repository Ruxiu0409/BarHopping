import SwiftUI

struct DrinkPassTicketDetailView: View {
    let purchase: DrinkPassPurchase
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    DrinkPassKeyVisual()
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                    DrinkPassTicketView(purchase: purchase)
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .foregroundStyle(AppTheme.textPrimary)
            .navigationTitle("我的酒票")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(AppTheme.accentOnDark)
    }
}
