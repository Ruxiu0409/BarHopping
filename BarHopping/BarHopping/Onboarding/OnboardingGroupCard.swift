import SwiftUI

struct OnboardingGroupCard: View {
    let group: SocialGroup
    let join: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text(group.name).font(.title3.bold())
                Label(group.drinkLevel.title, systemImage: group.drinkLevel.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accentOnDark)
                if let reminder = group.drinkLevel.reminder {
                    Text(reminder).font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
                Label("\(group.members.count) 位成員", systemImage: "person.2")
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                if let event = group.nextEvent {
                    VStack(alignment: .leading, spacing: 5) {
                        Label("下一場・\(event.title)", systemImage: "calendar")
                        Text(GroupsStyle.date(event.date))
                    }
                    .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                } else {
                    Text("還沒有下一場活動").font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Button(group.isJoined ? "已加入" : "加入", systemImage: group.isJoined ? "checkmark.circle.fill" : "person.badge.plus", action: join)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
                .controlSize(.large)
                .frame(minHeight: 44)
                .disabled(group.isJoined)
                .accessibilityLabel("\(group.isJoined ? "已加入" : "加入")\(group.name)")
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appGlassCard()
        .sensoryFeedback(.success, trigger: group.isJoined) { _, joined in joined }
    }
}
