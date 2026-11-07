import SwiftUI

struct OnboardingGroupCard: View {
    let group: SocialGroup
    var compact = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let join: () -> Void

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        details
                        joinButton
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        details
                        joinButton
                    }
                }
            } else {
                HStack(spacing: 12) {
                    details
                    joinButton
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 10 : 16)
        .appGradientCard(cornerRadius: 28)
        .sensoryFeedback(.success, trigger: group.isJoined) { _, joined in joined }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            Label(group.name, systemImage: group.symbol)
                .font(compact ? .subheadline.weight(.semibold) : .headline)
            Text("\(group.drinkLevel.title)・\(group.members.count) 位成員")
                .font(compact ? .caption : .subheadline)
                .foregroundStyle(AppTheme.accentOnDark)
            if let reminder = group.drinkLevel.reminder {
                Text(reminder).font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
            if let event = group.nextEvent {
                Text(compact ? "下一場・\(event.date.formatted(.dateTime.month().day()))" : "下一場・\(event.title)　\(GroupsStyle.date(event.date))")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityLabel("下一場・\(event.title)，\(GroupsStyle.date(event.date))")
            } else {
                Text("還沒有下一場活動")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var joinButton: some View {
        Button(group.isJoined ? "已加入" : "加入", systemImage: group.isJoined ? "checkmark.circle.fill" : "person.badge.plus", action: join)
            .font(.subheadline.weight(.semibold))
            .modifier(OnboardingActionStyle())
            .tint(AppTheme.accent)
            .frame(minHeight: 44)
            .fixedSize(horizontal: !dynamicTypeSize.isAccessibilitySize, vertical: true)
            .disabled(group.isJoined)
            .accessibilityLabel("\(group.isJoined ? "已加入" : "加入")\(group.name)")
    }
}
