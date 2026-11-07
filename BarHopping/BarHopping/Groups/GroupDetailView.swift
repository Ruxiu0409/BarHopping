import Foundation
import SwiftUI

struct GroupDetailView: View {
    let groupID: UUID
    @Environment(GroupsStore.self) private var store
    @Environment(PlannerStore.self) private var planner
    @Environment(\.dismiss) private var dismiss
    @State private var showCreateEvent = false
    @State private var showLeave = false
    @State private var message = ""
    @FocusState private var composing: Bool

    var body: some View {
        Group {
            if let group = store.group(groupID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header(group)
                        events(group)
                        members(group)
                        board(group)
                        if group.isJoined {
                            Button("退出團體", role: .destructive) { showLeave = true }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .confirmationDialog("退出「\(group.name)」？", isPresented: $showLeave, titleVisibility: .visible) {
                                    Button("退出團體", role: .destructive) { store.leave(groupID); dismiss() }
                                    Button("取消", role: .cancel) { }
                                } message: {
                                    Text("也會取消你在這個團體所有活動的參加狀態。\(group.isPublic ? "之後可從探索重新加入。" : "之後需使用邀請碼重新加入。")")
                                }
                        }
                    }
                    .padding(20)
                }
                .background(GroupsStyle.canvas)
                .navigationTitle(group.name)
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showCreateEvent) {
                    CreateGroupEventSheet(groupID: groupID, plan: planner.plan, distance: shareDistance)
                }
            } else {
                ContentUnavailableView("找不到團體", systemImage: "person.3")
            }
        }
    }

    private var shareDistance: Double? {
        guard planner.resultStatus == .current || planner.resultStatus == .savedEstimate,
              planner.result?.planId == planner.plan.id else { return nil }
        return planner.result?.distanceMeters
    }

    private func header(_ group: SocialGroup) -> some View {
        GroupCard {
            HStack(alignment: .top, spacing: 12) {
                GroupAvatar(symbol: group.symbol)
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name).font(.title2.bold())
                    Label(group.isPublic ? "公開團體" : "私密團體", systemImage: group.isPublic ? "globe.asia.australia" : "lock.fill")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            GroupTags(tags: group.tags)
            Text(group.introduction.isEmpty ? "團主還沒有填寫簡介，一起寫下第一次散步的故事吧。" : group.introduction)
                .font(.body)
            if group.isJoined {
                Label("你已是團體成員", systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.accentOnDark)
                if !group.isPublic {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("團體邀請碼").font(.caption).foregroundStyle(.secondary)
                        Text(group.inviteCode).font(.title3.monospaced().bold()).textSelection(.enabled)
                        ShareLink(item: "一起加入「\(group.name)」！在串酒吧的團體分頁輸入邀請碼：\(group.inviteCode)。這是本機示意，僅在同一個 App 工作階段有效。") {
                            Label("分享邀請碼", systemImage: "square.and.arrow.up")
                        }
                        .font(.subheadline)
                        Text("僅適用於這次本機體驗，無法跨裝置加入。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else if group.isPublic {
                Button("加入團體", systemImage: "person.badge.plus") { store.join(groupID) }
                    .buttonStyle(.borderedProminent).tint(AppTheme.accent)
            }
        }
    }

    private func events(_ group: SocialGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("揪團活動").font(.title2.bold())
            if group.isJoined {
                Button("分享目前規劃，建立揪團", systemImage: "plus.circle") { showCreateEvent = true }
                    .buttonStyle(.bordered).controlSize(.large)
                    .disabled(planner.plan.stops.isEmpty)
                if planner.plan.stops.isEmpty {
                    Text("先到地圖或路跑加入至少一個站點，就能把目前規劃分享成活動。")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("加入團體後，就能報名或建立揪團活動。")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if group.events.isEmpty {
                GroupCard {
                    Label("還沒有揪團活動", systemImage: "calendar.badge.plus").font(.headline)
                    Text("把喜歡的路線分享給團員，一起約個時間出發。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            ForEach(group.events.sorted { $0.date < $1.date }) { event in
                GroupCard {
                    NavigationLink(value: GroupsDestination.event(groupID: groupID, eventID: event.id)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text(event.title).font(.headline)
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
                            }
                            Label(GroupsStyle.date(event.date), systemImage: "calendar")
                            Label(event.meetingPoint, systemImage: "mappin.and.ellipse")
                            GroupRouteSummary(event: event)
                            Label("\(event.participantIDs.count) 人參加・\(event.isParticipating ? "你已參加" : "你尚未參加")", systemImage: event.isParticipating ? "checkmark.circle.fill" : "person.2")
                                .foregroundStyle(AppTheme.accentOnDark)
                        }
                        .font(.subheadline).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func members(_ group: SocialGroup) -> some View {
        GroupCard {
            DisclosureGroup {
                ForEach(group.members) { member in
                    HStack(alignment: .firstTextBaseline) {
                        Text(member.nickname)
                        Spacer()
                        Text(member.role).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                }
            } label: {
                Label("成員 \(group.members.count) 人", systemImage: "person.2").font(.headline)
            }
        }
    }

    private func board(_ group: SocialGroup) -> some View {
        GroupCard {
            Text("團體留言板").font(.title3.bold())
            if group.messages.isEmpty {
                Text("還沒有留言，向團員打聲招呼吧。")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(group.messages) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(entry.author).font(.subheadline.bold())
                        if entry.isAnnouncement {
                            Label("公告", systemImage: "megaphone.fill").font(.caption).foregroundStyle(AppTheme.accentOnDark)
                        }
                        Spacer(minLength: 0)
                    }
                    Text(entry.text).font(.body)
                    Text(GroupsStyle.date(entry.date)).font(.caption).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                Divider()
            }
            if group.isJoined {
                TextField("寫一則留言", text: $message, axis: .vertical)
                    .lineLimit(2...6).textFieldStyle(.roundedBorder).focused($composing)
                    .accessibilityLabel("留言內容")
                Button("送出留言", systemImage: "paperplane") {
                    store.post(message, groupID: groupID)
                    message = ""
                    composing = false
                }
                .buttonStyle(.bordered)
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                Text("加入團體後就能留言。")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
