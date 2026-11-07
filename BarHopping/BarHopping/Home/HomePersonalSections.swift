import SwiftUI

/// 打招呼與使用者資訊。
struct HomeGreetingHeader: View {
    let user: HomeUser

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<11: "早安"
        case 11..<17: "午安"
        default: "晚安"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(initials: user.initials, colorIndex: user.colorIndex, size: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(greeting)，\(user.nickname)")
                    .font(.title2.bold())
                Text(user.level)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// 本月統計。
struct HomeStatsRow: View {
    let stats: HomeStats
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let items: [(String, String, String)] = [
            ("figure.walk", Fmt.distance(stats.monthWalkedMeters), "本月步行"),
            ("wineglass", "\(stats.barsVisited) 間", "去過的店"),
            ("map", "\(stats.districtsExplored) 區", "探索過"),
        ]
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            ForEach(items, id: \.2) { icon, value, label in
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: icon).foregroundStyle(HomeTheme.accent)
                    Text(value).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                    Text(label).font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .homeCard(padding: 12)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(label) \(value)")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 單一任務卡。
struct HomeQuestCard: View {
    let quest: HomeQuest

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: quest.systemImage)
                    .font(.title3)
                    .foregroundStyle(HomeTheme.accent)
                    .frame(width: 40, height: 40)
                    .background(HomeTheme.accent.opacity(0.12), in: .circle)
                Spacer()
                Text(quest.kind.title)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(quest.title).font(.headline)
            Text(quest.detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            ProgressView(value: quest.fraction)
                .tint(HomeTheme.accent)
            HStack {
                Text(quest.progressText)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Label(quest.isCompleted ? "已獲得「\(quest.reward)」" : quest.reward,
                      systemImage: quest.isCompleted ? "checkmark.seal.fill" : "rosette")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(quest.isCompleted ? .white : HomeTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(quest.isCompleted ? HomeTheme.accent : HomeTheme.accent.opacity(0.1), in: .capsule)
            }
        }
        .homeCard(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(quest.kind.title)：\(quest.title)，\(quest.detail)")
        .accessibilityValue(quest.isCompleted ? "已完成，獲得徽章\(quest.reward)" : "進度 \(quest.progressText)，完成可獲得徽章\(quest.reward)")
    }
}

/// 任務區：一般字級水平捲動，輔助使用字級改直排。
struct HomeQuestSection: View {
    let quests: [HomeQuest]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 10) {
                ForEach(quests) { HomeQuestCard(quest: $0) }
            }
            .padding(.horizontal)
        } else {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(quests) { quest in
                        HomeQuestCard(quest: quest)
                            .frame(width: 240)
                            .frame(maxHeight: .infinity)
                    }
                }
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// 喝水、安全回家的溫和提醒。
struct HomeSafetyTip: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(.teal)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("小提醒").font(.subheadline.weight(.semibold))
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.teal.opacity(0.1), in: .rect(cornerRadius: HomeTheme.cornerRadius))
        .accessibilityElement(children: .combine)
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
