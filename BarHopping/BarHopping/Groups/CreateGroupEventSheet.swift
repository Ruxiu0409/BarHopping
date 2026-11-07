import Foundation
import SwiftUI

struct CreateGroupEventSheet: View {
    let groupID: UUID
    let plan: RoutePlan
    let distance: Double?
    @Environment(GroupsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date.now.addingTimeInterval(86400)
    @State private var meetingPoint = ""
    @State private var showError = false

    private var canCreate: Bool {
        !plan.stops.isEmpty && date > .now &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !meetingPoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("揪團資訊") {
                    TextField("活動名稱（必填）", text: $title)
                        .accessibilityLabel("活動名稱，必填")
                    DatePicker("集合時間", selection: $date, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    TextField("集合地點與說明（必填）", text: $meetingPoint, axis: .vertical)
                        .lineLimit(2...5).accessibilityLabel("集合地點與說明，必填")
                }
                Section {
                    Text(plan.title).font(.headline)
                    Text("\(plan.stops.count) 站・總距離\(distance.map(Fmt.distance) ?? "待計算")")
                    ForEach(plan.stops) { stop in
                        Label(stop.waypoint.name, systemImage: "mappin")
                    }
                    if plan.origin == nil {
                        Label("目前尚未設定路線起點，載入後請在路跑或地圖補齊。", systemImage: "info.circle")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                } header: { Text("分享目前規劃") } footer: {
                    Text("活動會保存開啟表單時的路線副本，之後修改目前規劃不會改動活動。距離供參考，出發前請重新計算。")
                }
                Section { GroupSafetyNote().listRowInsets(EdgeInsets()) }
            }
            .environment(\.locale, Locale(identifier: "zh_TW"))
            .navigationTitle("建立揪團活動")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        if store.createEvent(groupID: groupID, title: title, date: date, meetingPoint: meetingPoint, plan: plan, distance: distance) { dismiss() }
                        else { showError = true }
                    }.disabled(!canCreate)
                }
            }
            .alert("無法建立活動", isPresented: $showError) { } message: {
                Text("請確認你仍是團體成員，已填寫名稱與集合說明，並選擇未來的時間。")
            }
        }
        .tint(AppTheme.accentOnDark)
    }
}
