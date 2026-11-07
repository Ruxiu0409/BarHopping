import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(GroupsStore.self) private var groups
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(OnboardingConfig.drinkLevelKey) private var drinkLevelRawValue = ""
    @State private var step = 1
    @AccessibilityFocusState private var headingFocused: Bool

    private var selectedLevel: GroupDrinkLevel? { GroupDrinkLevel(rawValue: drinkLevelRawValue) }
    private var title: String {
        switch step {
        case 1: "從你的位置出發"
        case 2: "選擇你的酒量"
        default: "找個合拍的團體"
        }
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    progress
                        .id("onboarding.top")
                    VStack(alignment: .leading, spacing: 10) {
                        Text(title)
                            .font(.largeTitle.bold())
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($headingFocused)
                        Text(subtitle).foregroundStyle(AppTheme.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    stepContent
                        .id(step)
                        .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion))
                    actions
                }
                .padding(24)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(AppTheme.background)
            .foregroundStyle(AppTheme.textPrimary)
            .tint(AppTheme.accentOnDark)
            .preferredColorScheme(.dark)
            .interactiveDismissDisabled()
            .onChange(of: step) {
                scrollProxy.scrollTo("onboarding.top", anchor: .top)
                headingFocused = true
            }
        }
    }

    private var subtitle: String {
        switch step {
        case 1: "開啟定位，查看附近酒吧，也能在路跑途中完成「買酒」打卡。"
        case 2: "沒有標準答案，選擇讓自己舒服的步調。不喝酒也歡迎。"
        default: "依你的酒量，先推薦同級團體，再看看相鄰級的同行夥伴。"
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if step > 1 {
                    Button("上一步", systemImage: "chevron.left") { move(to: step - 1) }
                        .frame(minHeight: 44)
                }
                Spacer(minLength: 8)
                Text("步驟 \(step) / 3")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(AppTheme.accentOnDark)
            }
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? AppTheme.accentOnDark : AppTheme.elevated)
                        .frame(height: 4)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case 1:
            OnboardingLocationStep()
        case 2:
            VStack(spacing: 12) {
                ForEach(GroupDrinkLevel.allCases) { level in
                    OnboardingDrinkLevelCard(level: level, isSelected: selectedLevel == level) {
                        withAppAnimation(AppMotion.tap, reduceMotion: reduceMotion) {
                            drinkLevelRawValue = level.rawValue
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: drinkLevelRawValue)
        default:
            if let selectedLevel {
                let recommendations = OnboardingConfig.recommendations(from: groups.groups, for: selectedLevel)
                VStack(spacing: 16) {
                    ForEach(recommendations) { group in
                        OnboardingGroupCard(group: group) { groups.join(group.id) }
                    }
                    if recommendations.isEmpty {
                        ContentUnavailableView("暫時沒有合適的團體", systemImage: "person.3", description: Text("完成後可到團體分頁探索或建立團體。"))
                    }
                    Text("本機體驗・加入狀態只保留於這次 App 工作階段，不會通知其他人。")
                        .font(.caption).foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button(step == 3 ? "完成" : "下一步") {
                if step == 3 { onComplete() } else { move(to: step + 1) }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .controlSize(.large)
            .frame(maxWidth: .infinity, minHeight: 44)
            .disabled(step == 2 && selectedLevel == nil)
            .accessibilityHint(step == 2 && selectedLevel == nil ? "請先選擇一個酒量分類" : "")
            if step == 1 {
                Button("稍後再說") { move(to: 2) }
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else if step == 3 {
                Button("略過", action: onComplete)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
    }

    private func move(to nextStep: Int) {
        withAppAnimation(AppMotion.sheet, reduceMotion: reduceMotion) { step = nextStep }
    }
}
