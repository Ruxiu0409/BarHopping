import SwiftUI

struct OnboardingDrinkLevelCard: View {
    let level: GroupDrinkLevel
    let isSelected: Bool
    var compact = false
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(alignment: .top, spacing: compact ? 10 : 16) {
                Image(systemName: level.symbol)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accentOnDark)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(compact ? .subheadline.weight(.semibold) : .headline)
                    Text(level.description).font(compact ? .caption : .subheadline).foregroundStyle(AppTheme.textSecondary)
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
            .padding(compact ? 10 : 16)
            .frame(maxWidth: .infinity, minHeight: compact ? 56 : 80, alignment: .leading)
            .appGradientCard(cornerRadius: 28)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppTheme.accentSoft)
                        .overlay {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .strokeBorder(AppTheme.accentOnDark, lineWidth: 1.5)
                        }
                        .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("選擇\(level.title)，依此推薦團體")
    }
}
