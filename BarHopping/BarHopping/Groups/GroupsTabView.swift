import Foundation
import SwiftUI

struct GroupsTabView: View {
    @State private var store = GroupsStore()
    @State private var path: [GroupsDestination] = []
    @State private var section = Section.mine
    @State private var selectedTag: String?
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
            .navigationTitle("團體")
            .toolbar {
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
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { actionButtons }
                VStack(alignment: .leading, spacing: 8) { actionButtons }
            }
        }
    }

    @ViewBuilder private var actionButtons: some View {
        Button("建立團體", systemImage: "plus") { sheet = .create }
            .buttonStyle(.borderedProminent).tint(AppTheme.accent).foregroundStyle(AppTheme.textPrimary)
            .controlSize(.large).buttonBorderShape(.capsule)
        Button("邀請碼加入", systemImage: "key") { sheet = .invite }
            .buttonStyle(.bordered).controlSize(.large).buttonBorderShape(.capsule)
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
                    Button("建立我的團體") { sheet = .create }.buttonStyle(.bordered)
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
                    tagButton(nil)
                    ForEach(GroupsMockData.tags, id: \.self) { tagButton($0) }
                }
            }.scrollIndicators(.hidden)
            let groups = store.explore(tag: selectedTag)
            if groups.isEmpty {
                ContentUnavailableView("還沒有符合的團體", systemImage: "line.3.horizontal.decrease", description: Text("試試其他標籤，或建立一個新團體。"))
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
            }
        }
    }

    private func groupLink(_ group: SocialGroup) -> some View {
        GroupCard {
            NavigationLink(value: GroupsDestination.group(group.id)) { GroupSummary(group: group) }
                .buttonStyle(.plain)
        }
    }

    private func tagButton(_ tag: String?) -> some View {
        Button { selectedTag = tag } label: {
            HStack(spacing: 4) {
                if selectedTag == tag { Image(systemName: "checkmark") }
                Text(tag.map { "#\($0)" } ?? "全部")
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(selectedTag == tag ? GroupsStyle.accent : Color(.secondarySystemGroupedBackground), in: Capsule())
            .foregroundStyle(selectedTag == tag ? Color.white : Color.primary)
        }
        .accessibilityAddTraits(selectedTag == tag ? .isSelected : [])
    }
}
