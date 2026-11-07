import Foundation
import SwiftUI

struct GroupsTabView: View {
    private let title = "找個伴，走進下一條巷弄"
    @State private var store = GroupsStore()
    @State private var path: [GroupsDestination] = []
    @State private var section = Section.mine
    @State private var selectedDrinkLevel: GroupDrinkLevel?
    @State private var sheet: Sheet?

    private enum Section: String, CaseIterable { case mine = "我的團體", explore = "探索團體" }
    private enum Sheet: String, Identifiable { case create, invite; var id: String { rawValue } }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    introduction
                    Picker("團體清單", selection: $section) {
                        ForEach(Section.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if section == .mine { myGroups } else { exploreGroups }
                    Text("本機體驗・團體、活動與留言皆為示意資料，關閉 App 後不會保留，也不會傳送給其他人。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(GroupsStyle.canvas)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("團體操作", systemImage: "plus") {
                        Button("建立團體", systemImage: "person.3.fill") { sheet = .create }
                        Button("用邀請碼加入", systemImage: "key") { sheet = .invite }
                    }
                }
            }
            .navigationDestination(for: GroupsDestination.self) { destination in
                switch destination {
                case .group(let id): GroupDetailView(groupID: id)
                case .event(let groupID, let eventID): GroupEventDetailView(groupID: groupID, eventID: eventID)
                }
            }
            .sheet(item: $sheet) { presented in
                switch presented {
                case .create:
                    CreateGroupSheet { id in path.append(.group(id)) }
                case .invite:
                    JoinGroupSheet { id in path.append(.group(id)) }
                }
            }
        }
        .environment(store)
        .environment(\.locale, Locale(identifier: "zh_TW"))
        .tint(AppTheme.accentOnDark)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("台中・一起走走", systemImage: "location.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.accentOnDark)
            Text("找個伴，\n走進下一條巷弄。")
                .font(.largeTitle.bold()).fixedSize(horizontal: false, vertical: true)
            Text("分享喜歡的路線，約好時間輕鬆出發。")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder private var myGroups: some View {
        if store.myGroups.isEmpty {
            GroupCard {
                ContentUnavailableView {
                    Label("還沒有加入團體", systemImage: "person.3")
                } description: {
                    Text("找找台中同好，或建立自己的散步小隊。")
                } actions: {
                    Button("去探索團體") { section = .explore }.buttonStyle(.borderedProminent).tint(AppTheme.accent)
                }
            }
        } else {
            Text("我的同行夥伴 \(store.myGroups.count)").font(.title3.bold())
            ForEach(store.myGroups) { group in groupLink(group) }
        }
    }

    private var exploreGroups: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("找到合拍的散步夥伴").font(.title3.bold())
                Text("公開團體・新朋友也歡迎")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    drinkLevelButton(nil)
                    ForEach(GroupDrinkLevel.allCases) { drinkLevelButton($0) }
                }
            }.scrollIndicators(.hidden)
            if let level = selectedDrinkLevel {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.description)
                    if let reminder = level.reminder { Text(reminder) }
                }
                .font(.subheadline).foregroundStyle(.secondary)
            }
            let groups = store.explore(drinkLevel: selectedDrinkLevel)
            VStack(alignment: .leading, spacing: 16) {
                if groups.isEmpty {
                    ContentUnavailableView("還沒有符合的團體", systemImage: "line.3.horizontal.decrease", description: Text("試試其他喝酒程度，或從右上角建立團體。"))
                        .appTransition(.insertionRemoval)
                }
                ForEach(groups) { group in
                    GroupCard {
                        NavigationLink(value: GroupsDestination.group(group.id)) { GroupSummary(group: group) }
                            .buttonStyle(.plain)
                        Text(group.introduction).font(.subheadline).foregroundStyle(.secondary)
                        if group.isJoined {
                            Label("已加入", systemImage: "checkmark.circle.fill").font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.accentOnDark)
                        } else {
                            Button("加入團體", systemImage: "person.badge.plus") { store.join(group.id) }
                                .buttonStyle(.bordered).buttonBorderShape(.capsule)
                        }
                    }
                    .appTransition(.insertionRemoval)
                }
            }
            .appAnimation(value: groups.map(\.id))
        }
    }

    private func groupLink(_ group: SocialGroup) -> some View {
        GroupCard {
            NavigationLink(value: GroupsDestination.group(group.id)) { GroupSummary(group: group) }
                .buttonStyle(.plain)
        }
    }

    private func drinkLevelButton(_ level: GroupDrinkLevel?) -> some View {
        Button { selectedDrinkLevel = level } label: {
            HStack(spacing: 4) {
                if selectedDrinkLevel == level { Image(systemName: "checkmark") }
                if let level {
                    Label(level.title, systemImage: level.symbol)
                } else {
                    Text("全部")
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(selectedDrinkLevel == level ? GroupsStyle.accent : Color(.secondarySystemGroupedBackground), in: Capsule())
            .foregroundStyle(selectedDrinkLevel == level ? Color.white : Color.primary)
        }
        .accessibilityAddTraits(selectedDrinkLevel == level ? .isSelected : [])
    }
}
