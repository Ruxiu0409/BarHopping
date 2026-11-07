import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(GroupsStore.self) private var groups
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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
        case 1: "逢酒必喝 BarHopping"
        case 2: "選擇你的酒量"
        default: "找個合拍的團體"
        }
    }
    private var greeting: String {
        switch step {
        case 1: "hello"
        case 2: "cheers"
        default: "let's go"
        }
    }
    private var subtitle: String {
        switch step {
        case 1: "開啟定位，查看附近酒吧，也能在路跑途中完成「買酒」打卡。"
        case 2: "沒有標準答案，選擇讓自己舒服的步調。不喝酒也歡迎。"
        default: "依你的酒量，先推薦同級團體，再看看相鄰級的同行夥伴。"
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 740 || dynamicTypeSize >= .xxLarge
            VStack(spacing: 0) {
                navigation
                if dynamicTypeSize.isAccessibilitySize {
                    ViewThatFits(in: .vertical) {
                        page(compact: true, availableHeight: geometry.size.height)
                            .fixedSize(horizontal: false, vertical: true)
                        ScrollView {
                            page(compact: true, availableHeight: geometry.size.height)
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                    .id(step)
                    .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion))
                } else {
                    ViewThatFits(in: .vertical) {
                        page(compact: compact, availableHeight: geometry.size.height)
                            .fixedSize(horizontal: false, vertical: true)
                        page(compact: true, availableHeight: geometry.size.height)
                    }
                    .id(step)
                    .transition(AppMotion.transition(.reveal, reduceMotion: reduceMotion))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: 528)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .onChange(of: step) { headingFocused = true }
    }

    private func page(compact: Bool, availableHeight: CGFloat) -> some View {
        VStack(spacing: compact ? 8 : 16) {
            VStack(spacing: compact ? 8 : 14) {
                stepContent(compact: compact)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            footer(compact: compact, availableHeight: availableHeight)
        }
        .padding(.horizontal, compact ? 20 : 24)
        .padding(.top, compact ? 4 : 12)
        .padding(.bottom, 8)
    }

    private var navigation: some View {
        HStack {
            if step > 1 {
                Button("上一步", systemImage: "chevron.left") { move(to: step - 1) }
                    .frame(minHeight: 44)
            }
            Spacer(minLength: 8)
            Text("逢酒必喝 BarHopping")
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(AppTheme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 44)
    }

    private func footer(compact: Bool, availableHeight: CGFloat) -> some View {
        VStack(spacing: compact ? 6 : 10) {
            Text(greeting)
                .font(.onboardingHello(size: min(64, max(44, availableHeight * 0.07))))
                .foregroundStyle(AppTheme.accentOnDark)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .accessibilityHidden(true)
            VStack(spacing: 2) {
                Text(step == 1 ? "逢酒必喝" : title)
                    .font(compact ? .title2.weight(.semibold) : .largeTitle.weight(.semibold))
                    .minimumScaleFactor(0.8)
                if step == 1 {
                    Text("BarHopping")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isHeader)
            .accessibilityFocused($headingFocused)
            Text(subtitle)
                .font(compact ? .subheadline : .body)
                .minimumScaleFactor(0.85)
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? AppTheme.accentOnDark : AppTheme.textTertiary)
                        .frame(width: index == step ? 20 : 6, height: 6)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("步驟 \(step)，共 3 步")
            actions.padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder private func stepContent(compact: Bool) -> some View {
        switch step {
        case 1:
            OnboardingLocationStep(compact: compact)
        case 2:
            VStack(spacing: compact ? 6 : 12) {
                ForEach(GroupDrinkLevel.allCases) { level in
                    OnboardingDrinkLevelCard(level: level, isSelected: selectedLevel == level, compact: compact) {
                        withAppAnimation(AppMotion.tap, reduceMotion: reduceMotion) {
                            drinkLevelRawValue = level.rawValue
                        }
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: drinkLevelRawValue)
        default:
            VStack(spacing: compact ? 6 : 12) {
                ForEach(recommendedIDs, id: \.self) { id in
                    if let group = groups.group(id) {
                        OnboardingGroupCard(group: group, compact: compact) { groups.join(id) }
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
                    .font(.caption2).foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 4) {
            Button(action: advance) {
                Text(step == 3 ? "完成" : "下一步")
                    .font(.headline)
                    .frame(minWidth: 160, minHeight: 46)
                    .padding(.horizontal, 12)
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(AppTheme.accent.opacity(step == 2 && selectedLevel == nil ? 0.4 : 1), in: Capsule())
            .disabled(step == 2 && selectedLevel == nil)
            .accessibilityHint(step == 2 && selectedLevel == nil ? "請先選擇一個酒量分類" : "")
            if step == 1 {
                secondaryAction("稍後再說") { move(to: 2) }
            } else if step == 3 {
                secondaryAction("略過", action: onComplete)
            }
        }
    }

    private func secondaryAction(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
