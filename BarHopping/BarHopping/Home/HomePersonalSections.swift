import SwiftUI
import UIKit

/// 與「你」分頁共用個人資料的精簡入口。
struct HomeGreetingHeader: View {
    @Environment(UserProfileStore.self) private var userProfile
    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button {
            router.selectedTab = .profile
        } label: {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
            layout {
                avatar

                VStack(alignment: .leading, spacing: 7) {
                    Text(userProfile.nickname)
                        .font(.title2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text(userProfile.levelTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accentOnDark)
                    Text(userProfile.profileHandle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .accessibilityHidden(true)
            }
            .multilineTextAlignment(.leading)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGradientCard(cornerRadius: 22)
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("切換到你分頁，查看或編輯個人檔案")
        .accessibilityInputLabels(["個人檔案", userProfile.nickname])
    }

    // ProfileTabView.avatarView 是私有方法；維持相同圖片優先順序、尺寸與外圈。
    private var avatar: some View {
        Group {
            if let data = userProfile.customAvatarData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let preset = userProfile.customAvatarImage {
                preset
                    .resizable()
                    .scaledToFit()
                    .padding(92 * 0.25)
                    .foregroundStyle(AppTheme.accentOnDark)
                    .background(AppTheme.accentSoft)
            } else {
                Image(UserAvatarIcon.assetName)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: 92, height: 92)
        .clipShape(Circle())
        .overlay {
            Circle().strokeBorder(
                LinearGradient(
                    colors: [AppTheme.accentOnDark, AppTheme.accent, AppTheme.accentOnDark.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
        }
        .accessibilityHidden(true)
    }
}

/// 與「你」分頁一致的累積統計。
struct HomeStatsRow: View {
    @Environment(UserProfileStore.self) private var userProfile
    @Environment(AppRouter.self) private var router
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let items: [(icon: String, value: String, title: String, color: Color)] = [
            ("wineglass.fill", "\(userProfile.visitedBarsCount) 間", "已踩點酒吧", AppTheme.accentOnDark),
            ("figure.walk", String(format: "%.1f km", userProfile.totalWalkingKm), "累積步行", AppTheme.info),
            ("heart.fill", userProfile.soberScore, "目前狀態", AppTheme.success),
        ]
        Button {
            router.selectedTab = .profile
        } label: {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 12))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
            layout {
                ForEach(items, id: \.title) { item in
                    VStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .font(.title2)
                            .foregroundStyle(item.color)
                            .accessibilityHidden(true)
                        Text(item.value)
                            .font(.headline)
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(item.title)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .appGradientCard(cornerRadius: 14)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(item.title)，\(item.value)")
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("切換到你分頁，查看完整個人資料")
        .accessibilityInputLabels(["跑吧統計"])
    }
}

/// 區塊標題。
struct HomeSectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
            Spacer()
            trailing
        }
        .padding(.horizontal)
    }
}
