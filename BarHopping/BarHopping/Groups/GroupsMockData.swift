import Foundation

/// 所有團體均為虛構；座標在台中街道附近，距離僅為活動示意估算。
enum GroupsMockData {
    static let tags = ["西區", "逢甲", "七期", "精釀", "調酒", "新手友善"]

    static func makeGroups(now: Date = .now) -> [SocialGroup] {
        let definitions: [(String, String, [String], String, String, Bool, Bool)] = [
            ("草悟道精釀研究社", "沿著草悟道慢慢走，認識不同風味，也認識新朋友。不喝酒也歡迎一起散步。", ["西區", "精釀", "新手友善"], "leaf.fill", "WALK88", true, true),
            ("逢甲下班小酌團", "下班後留一點時間給自己。從逢甲街區出發，輕鬆走訪巷弄裡的小店。", ["逢甲", "調酒", "新手友善"], "moon.stars.fill", "FENG66", true, false),
            ("七期微醺散步俱樂部", "在城市燈光下散步聊天，每次選幾間小店，依自己的步調參加。", ["七期", "調酒"], "building.2.fill", "CITY28", true, false),
            ("週末巷口散步隊", "熟朋友的週末小聚，先約好回家方式，再一起出門走走。", ["西區", "新手友善"], "figure.walk", "LANE18", false, false)
        ]
        return definitions.enumerated().map { index, item in
            let admin = GroupMember(id: "host-\(index)", nickname: ["阿禾", "小鹿", "米粒", "阿哲"][index], isAdmin: true)
            var members = [admin, GroupMember(id: "member-\(index)-1", nickname: "小安", isAdmin: false), GroupMember(id: "member-\(index)-2", nickname: "木木", isAdmin: false)]
            if item.6 { members.append(GroupMember(id: GroupMember.currentID, nickname: "我", isAdmin: false)) }
            let plan = route(index: index, now: now)
            let event = GroupEvent(id: UUID(), title: ["週末草悟道慢慢走", "下班後的逢甲小聚", "七期夜色散步", "週末巷口見"][index], date: futureDate(days: index + 2, now: now), meetingPoint: plan.origin?.name ?? "草悟道入口", plan: plan, distanceMeters: [1800, 1500, 2200, 1600][index], participantIDs: [admin.id, members[1].id])
            return SocialGroup(id: UUID(), name: item.0, introduction: item.1, isPublic: item.5, tags: item.2, symbol: item.3, inviteCode: item.4, members: members, lastActiveAt: now.addingTimeInterval(Double(-index - 1) * 3600), events: [event], messages: [
                GroupMessage(id: UUID(), author: admin.nickname, text: "歡迎加入！依自己的步調參加，無酒精飲品也很棒。集合前請先安排好回家的方式。", date: now.addingTimeInterval(-7200), isAnnouncement: true),
                GroupMessage(id: UUID(), author: "小安", text: "期待一起認識台中的巷弄，下次集合見！", date: now.addingTimeInterval(-3600), isAnnouncement: false)
            ])
        }
    }

    private static func futureDate(days: Int, now: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day) ?? day
    }

    private static func route(index: Int, now: Date) -> RoutePlan {
        let streets: [(String, Double, Double)] = [
            ("草悟道・公益路口", 24.1510, 120.6637),
            ("逢甲路・福星路口", 24.1793, 120.6459),
            ("臺中國家歌劇院廣場", 24.1625, 120.6404),
            ("美術園道・五權西路口", 24.1395, 120.6632)
        ]
        let street = streets[index]
        let origin = Waypoint.custom(name: street.0, at: Coordinate(latitude: street.1, longitude: street.2))
        let names = [["葉影釀所", "巷尾小酌", "暮光吧台"], ["星巷調飲室", "轉角麥香"], ["夜光小室", "城市杯緣", "樹下調飲"], ["木窗小館", "巷口釀室"]][index]
        let stops = names.enumerated().map { offset, name in
            Stop(waypoint: Waypoint(id: UUID().uuidString, name: name, coordinate: Coordinate(latitude: street.1 + Double(offset + 1) * 0.0015, longitude: street.2 + (offset % 2 == 0 ? 0.001 : -0.001)), placeId: nil), dwellMinutes: 30)
        }
        return RoutePlan(id: UUID().uuidString, title: ["草悟道晚風散步", "逢甲下班散步", "七期夜色散步", "美術園道小聚"][index], origin: origin, stops: stops, endMode: .returnToOrigin, destination: nil, updatedAt: now)
    }
}
