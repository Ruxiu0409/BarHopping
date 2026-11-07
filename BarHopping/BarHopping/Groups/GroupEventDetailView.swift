import Foundation
import SwiftUI

struct GroupEventDetailView: View {
    let groupID: UUID
    let eventID: UUID
    @Environment(GroupsStore.self) private var store
    @Environment(PlannerStore.self) private var planner
    @Environment(AppRouter.self) private var router
    @State private var loadTarget = LoadTarget.run
    @State private var showLoadConfirmation = false
    private enum LoadTarget: String, Identifiable {
        case run, map
        var id: String { rawValue }
    }

    var body: some View {
        Group {
            if let event = store.event(groupID: groupID, eventID: eventID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        GroupCard {
                            Label("揪團活動", systemImage: "calendar").font(.subheadline).foregroundStyle(GroupsStyle.ink)
                            Text(event.title).font(.title.bold())
                            Label(GroupsStyle.date(event.date), systemImage: "clock")
                            Label(event.meetingPoint, systemImage: "mappin.and.ellipse")
                            GroupRouteSummary(event: event)
                            Label("\(event.participantIDs.count) 人參加", systemImage: "person.2")
                            if store.group(groupID)?.isJoined == true {
                                Button(event.isParticipating ? "不參加這次活動" : "參加這次活動", systemImage: event.isParticipating ? "checkmark.circle.fill" : "plus.circle") {
                                    store.toggleParticipation(groupID: groupID, eventID: eventID)
                                }
                                .buttonStyle(.borderedProminent).controlSize(.large)
                                .disabled(event.date <= .now)
                                if event.date <= .now { Text("活動已結束").font(.caption).foregroundStyle(.secondary) }
                            } else {
                                Text("加入團體後，就能參加活動。")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        route(event)
                        GroupSafetyNote()
                        Text("本機示意活動，參加狀態不會通知其他人。店名為虛構，請勿直接前往。")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(20)
                }
                .background(GroupsStyle.canvas)
                .navigationTitle("活動詳情")
                .navigationBarTitleDisplayMode(.inline)
                .alert("取代目前的規劃？", isPresented: $showLoadConfirmation) {
                    Button("取消", role: .cancel) { }
                    Button("取代並開啟", role: .destructive) {
                        planner.load(SavedDraft(plan: event.plan, result: nil, savedAt: .now))
                        if loadTarget == .map { router.showRouteOnMap() }
                        else { router.selectedTab = .run }
                    }
                } message: {
                    Text("「\(event.plan.title)」會取代目前規劃。尚未儲存的變更將不會保留；載入後可重新計算步行路線。")
                }
            } else {
                ContentUnavailableView("找不到活動", systemImage: "calendar.badge.exclamationmark")
            }
        }
    }

    private func route(_ event: GroupEvent) -> some View {
        GroupCard {
            Text(event.plan.title).font(.title3.bold())
            if let origin = event.plan.origin {
                Label("集合起點・\(origin.name)", systemImage: "location.circle")
            }
            ForEach(Array(event.plan.stops.enumerated()), id: \.element.id) { index, stop in
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("\(index + 1)").font(.subheadline.monospacedDigit().bold()).foregroundStyle(GroupsStyle.ink)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(stop.waypoint.name).font(.headline)
                        Text("停留 \(Fmt.minutes(stop.dwellMinutes))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }.accessibilityElement(children: .combine)
            }
            Label(event.plan.endMode == .returnToOrigin ? "回到起點" : "終點・\(event.plan.destination?.name ?? "待設定")", systemImage: "flag.checkered")
                .font(.subheadline)
            Button("用這條路線", systemImage: "figure.walk") { loadTarget = .run; showLoadConfirmation = true }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .accessibilityHint("確認取代目前規劃後，前往路跑分頁")
            Button("在地圖查看", systemImage: "map") { loadTarget = .map; showLoadConfirmation = true }
                .buttonStyle(.bordered).controlSize(.large)
                .accessibilityHint("確認取代目前規劃後，前往地圖分頁")
        }
    }
}
