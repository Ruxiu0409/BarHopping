import SwiftUI

struct OnboardingDrinkLevelCard: View {
    let level: GroupDrinkLevel
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: level.symbol)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accentOnDark)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text(level.title).font(.headline)
                    Text(level.description).font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                    if let reminder = level.reminder {
                        Text(reminder).font(.caption).foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(AppTheme.accentOnDark)
                    .accessibilityHidden(true)
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .appGlassCard()
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .strokeBorder(isSelected ? AppTheme.accentOnDark : AppTheme.separator, lineWidth: isSelected ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("選擇\(level.title)，依此推薦團體")
    }
}
