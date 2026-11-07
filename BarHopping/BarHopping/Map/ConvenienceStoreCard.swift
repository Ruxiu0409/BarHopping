import Foundation
import SwiftUI

struct ConvenienceStoreCard: View {
    var store: ConvenienceStore
    var onAdd: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.name).font(.headline).lineLimit(2)
                    Text(store.brand.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(MapTheme.textSecondary)
                }
                Spacer(minLength: 8)
                Button("關閉", systemImage: "xmark", action: onClose)
                    .labelStyle(.iconOnly)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(MapTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(MapTheme.elevated, in: Circle())
            }
            Label(detail(store.address), systemImage: "mappin.and.ellipse")
                .lineLimit(2)
            Label(detail(store.openingHoursText), systemImage: "clock")
                .lineLimit(2)
            Button(action: onAdd) {
                Label("加入為自訂站點", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(MapTheme.accent)
        }
        .font(.subheadline)
        .mapCard()
    }

    private func detail(_ text: String?) -> String {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return "未提供" }
        return text
    }
}
