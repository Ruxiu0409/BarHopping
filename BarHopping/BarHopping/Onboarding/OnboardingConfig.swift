import Foundation

enum OnboardingConfig {
    static let showsOnEveryLaunch = true
    static let recommendedGroupCount = 3
    static let completionKey = "onboarding.completed"
    static let drinkLevelKey = "onboarding.drinkLevel"

    static func recommendations(from groups: [SocialGroup], for level: GroupDrinkLevel) -> [SocialGroup] {
        let levels = GroupDrinkLevel.allCases
        guard let selectedIndex = levels.firstIndex(of: level) else { return [] }
        return groups.enumerated().compactMap { index, group -> (index: Int, distance: Int, group: SocialGroup)? in
            // 只推薦公開且尚未加入的團體；isJoined 以目前使用者的成員 ID 判斷。
            guard group.isPublic, !group.isJoined, let levelIndex = levels.firstIndex(of: group.drinkLevel) else { return nil }
            let distance = abs(levelIndex - selectedIndex)
            guard distance <= 1 else { return nil }
            return (index, distance, group)
        }
        .sorted { lhs, rhs in
            lhs.distance == rhs.distance ? lhs.index < rhs.index : lhs.distance < rhs.distance
        }
        .prefix(recommendedGroupCount)
        .map(\.group)
    }
}
