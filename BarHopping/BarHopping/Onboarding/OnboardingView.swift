import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(GroupsStore.self) private var groups
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(OnboardingConfig.drinkLevelKey) private var drinkLevelRawValue = ""
    @State private var step = 1
    // 每次進入推薦頁固定名單；當頁加入後仍從共用 store 取得最新狀態。
    @State private var recommendedIDs: [SocialGroup.ID] = []
    @AccessibilityFocusState private var headingFocused: Bool

    private var selectedLevel: GroupDrinkLevel? { GroupDrinkLevel(rawValue: drinkLevelRawValue) }
    private var title: String {
        switch step {
        case 1: "從你的位置出發"
        case 2: "選擇你的酒量"
        default: "找個合拍的團體"
        }
    }
    private var symbol: String {
        switch step {
        case 1: "location.fill"
        case 2: selectedLevel?.symbol ?? "wineglass"
        default: "person.3.fill"
        }
    }
    private var subtitle: String {
        switch step {
        case 1: "開啟定位，查看附近酒吧，也能在路跑途中完成「買酒」打卡。"
        case 2: "沒有標準答案，選擇讓自己舒服的步調。不喝酒也歡迎。"
        default: "依你的酒量，先推薦同級團體，再看看相鄰級的同行夥伴。"
        }
    }

    private var pinsFooter: Bool { !dynamicTypeSize.isAccessibilitySize && verticalSizeClass != .compact }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                GlassEffectContainer(spacing: 24) {
                    VStack(spacing: 24) {
                        OnboardingHero(symbol: symbol)
                            .id("onboarding.top")
                        stepContent
                        if !pinsFooter { footer }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 480)
                    .frame(maxWidth: .infinity)
                    .id(step)
                    .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion))
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .top, spacing: 0) { navigation }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if pinsFooter { footer }
            }
            .background {
                AppTheme.background.ignoresSafeArea()
                if !reduceTransparency {
                    RadialGradient(colors: [AppTheme.accent.opacity(0.25), .clear], center: .top, startRadius: 0, endRadius: 420)
                        .ignoresSafeArea()
                }
            }
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

    private var navigation: some View {
        HStack {
            if step > 1 {
                Button("上一步", systemImage: "chevron.left") { move(to: step - 1) }
                    .frame(minHeight: 44)
            }
            Spacer(minLength: 8)
            Text("BarHopping")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? AppTheme.accentOnDark : AppTheme.textTertiary)
                        .frame(width: index == step ? 20 : 6, height: 6)
                }
            }
            .padding(.bottom, 8)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("步驟 \(step)，共 3 步")
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($headingFocused)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(AppTheme.textSecondary)
            actions.padding(.top, 8)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: 528)
        .frame(maxWidth: .infinity)
        .background(AppTheme.background)
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
            VStack(spacing: 16) {
                ForEach(recommendedIDs, id: \.self) { id in
                    if let group = groups.group(id) {
                        OnboardingGroupCard(group: group) { groups.join(id) }
                    }
                }
                if recommendedIDs.isEmpty {
                    ContentUnavailableView(
                        groups.groups.contains { $0.isPublic && !$0.isJoined }
                            ? "暫時沒有合適的團體" : "附近的團體你都加入了",
                        systemImage: "person.3",
                        description: Text("完成後可到團體分頁探索或建立團體。")
                    )
                }
                Text("本機體驗・加入狀態只保留於這次 App 工作階段，不會通知其他人。")
                    .font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 4) {
            Button(action: advance) {
                Text(step == 3 ? "完成" : "下一步")
                    .font(.headline)
                    .frame(minWidth: 160, minHeight: 32)
                    .padding(.horizontal, 12)
            }
            .modifier(OnboardingActionStyle())
            .tint(AppTheme.accent)
            .controlSize(.large)
            .disabled(step == 2 && selectedLevel == nil)
            .accessibilityHint(step == 2 && selectedLevel == nil ? "請先選擇一個酒量分類" : "")
            if step == 1 {
                Button("稍後再說") { move(to: 2) }
                    .frame(minHeight: 44)
            } else if step == 3 {
                Button("略過", action: onComplete)
                    .frame(minHeight: 44)
            }
        }
    }

    private func advance() {
        if step == 3 { onComplete() } else { move(to: step + 1) }
    }

    private func move(to nextStep: Int) {
        if nextStep == 3, let selectedLevel {
            recommendedIDs = OnboardingConfig.recommendations(from: groups.groups, for: selectedLevel).map(\.id)
        }
        withAppAnimation(AppMotion.sheet, reduceMotion: reduceMotion) { step = nextStep }
    }
}
