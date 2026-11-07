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
                    .foregroundStyle(AppTheme.textSecondary)
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
                    Image(systemName: icon).foregroundStyle(HomeTheme.accentOnDark)
                    Text(value).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
                    Text(label).font(.caption).foregroundStyle(AppTheme.textSecondary)
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
