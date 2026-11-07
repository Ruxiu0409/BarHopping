import Foundation
import SwiftUI

// 橘色用於主要操作，文字採深橘以維持淺底上的可讀性。
enum GroupsStyle {
    static let orange = Color(red: 252 / 255, green: 82 / 255, blue: 0)
    static let ink = Color(red: 0.67, green: 0.20, blue: 0)
    static let canvas = Color(.systemGroupedBackground)

    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.locale(Locale(identifier: "zh_TW")).month().day().weekday(.abbreviated).hour().minute())
    }
}

struct GroupCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) { content }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 22))
    }
}

struct GroupTags: View {
    let tags: [String]
    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(GroupsStyle.orange.opacity(0.08), in: Capsule())
                        .foregroundStyle(GroupsStyle.ink)
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct GroupAvatar: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.title2)
            .foregroundStyle(GroupsStyle.ink)
            .frame(width: 52, height: 52)
            .background(GroupsStyle.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 17))
            .accessibilityHidden(true)
    }
}

struct GroupSummary: View {
    let group: SocialGroup
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                GroupAvatar(symbol: group.symbol)
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name).font(.headline).foregroundStyle(.primary)
                    Label("\(group.members.count) 位成員・\(group.isPublic ? "公開" : "私密")", systemImage: group.isPublic ? "person.2" : "lock")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            GroupTags(tags: group.tags)
            if let next = group.nextEvent {
                Label("下次揪團 \(GroupsStyle.date(next.date))", systemImage: "calendar")
                    .font(.subheadline).foregroundStyle(GroupsStyle.ink)
            } else {
                Label("還沒有下一次揪團", systemImage: "calendar").font(.subheadline).foregroundStyle(.secondary)
            }
            HStack(spacing: 4) {
                Text("最近活動")
                Text(group.lastActiveAt, style: .relative)
                Text("前")
            }
            .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct GroupRouteSummary: View {
    let event: GroupEvent
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label("\(event.plan.stops.count) 站・總距離\(event.distanceMeters.map(Fmt.distance) ?? "待計算")", systemImage: "figure.walk")
                .font(.subheadline)
            Text(event.distanceMeters == nil ? "前往路跑分頁計算實際步行路線" : "活動示意估算，載入後請重新計算步行路線")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct GroupSafetyNote: View {
    var body: some View {
        Label {
            Text("結伴同行、記得多喝水，出發前先安排安全回家的方式。飲酒後不開車，也不騎車；不喝酒也歡迎一起走。")
        } icon: {
            Image(systemName: "heart.text.clipboard")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(16)
        .background(GroupsStyle.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
    }
}
