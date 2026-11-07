import Foundation

/// 團體、成員、活動和留言皆為本機示意；路線店家取自 App 內附的臺中 OSM 目錄。
enum GroupsMockData {
    static let tags = ["西區", "逢甲", "七期", "精釀", "調酒", "新手友善"]

    private static let roster: [(String, String)] = [
        ("member-yiwen", "以文"), ("member-jason", "Jason"), ("member-mika", "Mika"),
        ("member-cheng", "小陳"), ("member-vicky", "Vicky"), ("member-hao", "阿豪"),
        ("member-lin", "小林"), ("member-yu", "小宇"), ("member-ting", "婷婷"),
    ]

    private static let activityTitles = [
        "勤美散步・精釀兩站", "逢甲下班小聚", "歌劇院周邊・慢慢走兩站",
        "美術園道晚餐後散步",
    ]
    private static let announcements = [
        "這次先排兩站，想提早離開或只散步聊天都可以，集合前再確認店家營業狀況。",
        "逢甲小聚先抓 19:30 集合，晚到的人在群裡說一聲就好，不用趕路。",
        "這次走歌劇院周邊，會留時間休息；不喝酒或改喝無酒精都很自在。",
        "美術園道先吃晚餐再散步，路線只作規劃參考，出發前會再看一次店家資訊。",
        "本週改走無酒精友善路線，想帶朋友來也可以，記得先回覆大概人數。",
        "逢甲散步不趕店，大家到齊後再決定停留多久，回程方式也可以先討論。",
        "集合後先找地方坐下來聊聊，飲品依個人狀況選擇，完全不勸酒。",
        "這次以精釀交流為主，每站都可以只點無酒精飲品或跳過。",
        "品飲團預計控制在小團，路線與店家資訊當天出發前再確認。",
    ]
    private static let replies = [
        "我可以準時到，先走第一站就好。", "收到，我下班後直接過去，晚到會先留言。",
        "想參加，這次我會選無酒精的。", "謝謝整理路線，我先確認回程交通。",
        "我可以帶一位朋友，會先在這裡更新人數。", "好期待！我會先看一下集合點附近怎麼走。",
        "收到，慢慢走就好，我大約八點到。", "這次想試試精釀，也會記得補水。",
        "我先保留時間，出發前再確認能不能到。",
    ]

    static func makeGroups(now: Date = .now) -> [SocialGroup] {
        let definitions: [(String, String, [String], String, String, Bool, Bool, GroupDrinkLevel)] = [
            ("草悟道精釀研究社", "沿著草悟道慢慢走，認識不同風味，也認識新朋友。不喝酒也歡迎一起散步。", ["西區", "精釀", "新手友善"], "leaf.fill", "WALK88", true, true, .light),
            ("逢甲下班小酌團", "下班後留一點時間給自己。從逢甲街區出發，輕鬆走訪巷弄裡的小店。", ["逢甲", "調酒", "新手友善"], "moon.stars.fill", "FENG66", true, false, .light),
            ("七期微醺散步俱樂部", "在城市燈光下散步聊天，每次選幾間小店，依自己的步調參加。", ["七期", "調酒"], "building.2.fill", "CITY28", true, false, .tipsy),
            ("週末巷口散步隊", "熟朋友的週末小聚，先約好回家方式，再一起出門走走。", ["西區", "新手友善"], "figure.walk", "LANE18", false, false, .alcoholFree),
            ("草悟道無酒精散步團", "帶杯喜歡的無酒精飲品，一起走走聊聊。", ["西區", "新手友善"], "cup.and.saucer.fill", "ZERO01", true, false, .alcoholFree),
            ("逢甲清醒夜遊隊", "不喝酒也能享受夜晚，巷弄美食和聊天都歡迎。", ["逢甲", "新手友善"], "moon.stars.fill", "ZERO02", true, false, .alcoholFree),
            ("美術園道微醺小聚", "找間安靜小店，依自己的步調品味調酒與聊天。", ["西區", "調酒"], "leaf.fill", "TIPS02", true, false, .tipsy),
            ("西區風味交流社", "一起認識精釀風味，想休息隨時換無酒精飲品。", ["西區", "精釀"], "mug.fill", "TASTE1", true, false, .social),
            ("七期週末品飲團", "分享喜歡的酒款與故事，不勸酒、不拚杯。", ["七期", "調酒"], "wineglass.fill", "TASTE2", true, false, .social)
        ]
        return definitions.enumerated().map { index, item in
            let routeIndex = [0, 1, 2, 0, 0, 1, 3, 0, 2][index]
            let admin = GroupMember(id: "host-\(index)", nickname: ["阿禾", "小鹿", "米粒", "阿哲"][routeIndex], isAdmin: true)
            let memberCount = [5, 4, 6, 3, 5, 4, 6, 5, 4][index]
            var members = [admin] + roster.prefix(memberCount).map {
                GroupMember(id: "\($0.0)-\(index)", nickname: $0.1, isAdmin: false)
            }
            if item.6 { members.append(GroupMember(id: GroupMember.currentID, nickname: "我", isAdmin: false)) }
            let plan = route(index: routeIndex, now: now)
            let participants = Set([admin.id] + members.dropFirst().prefix(2).map(\.id))
            let event = GroupEvent(id: UUID(), title: activityTitles[routeIndex], date: futureDate(days: index + 2, hour: [19, 19, 20, 18][routeIndex], now: now), meetingPoint: plan.origin?.name ?? "草悟道入口", plan: plan, distanceMeters: nil, participantIDs: participants)
            let activeMember = members[min(1, members.count - 1)]
            let secondMember = members[min(2, members.count - 1)]
            return SocialGroup(id: UUID(), name: item.0, introduction: item.1, isPublic: item.5, drinkLevel: item.7, tags: item.2, symbol: item.3, inviteCode: item.4, members: members, lastActiveAt: now.addingTimeInterval(Double(-[12, 35, 75, 165, 310, 520, 740, 1_100, 1_560][index]) * 60), events: [event], messages: [
                GroupMessage(id: UUID(), author: admin.nickname, text: announcements[index], date: now.addingTimeInterval(-86_400), isAnnouncement: true),
                GroupMessage(id: UUID(), author: activeMember.nickname, text: replies[index], date: now.addingTimeInterval(-5_400), isAnnouncement: false),
                GroupMessage(id: UUID(), author: secondMember.nickname, text: "我先把時間留起來，出發前再確認集合地點。", date: now.addingTimeInterval(-1_200), isAnnouncement: false),
            ])
        }
    }

    private static func futureDate(days: Int, hour: Int, now: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let day = calendar.date(byAdding: .day, value: days, to: now) ?? now
        return calendar.date(bySettingHour: hour, minute: 30, second: 0, of: day) ?? day
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
        let names = [
            ["Bar MED", "吳留手串燒居酒屋", "放醉城巿餐酒館"],
            ["金茗茗茶酒館", "SPIKE 飛鏢酒吧"],
            ["禾樂精釀-新光遠百門市", "Drunken-duck Beer House"],
            ["Vender Bar", "月聲", "那晚 the night"],
        ][index]
        let places: [Place] = (try? MockFixtures.places.get()) ?? []
        let stops = names.enumerated().compactMap { offset, name -> Stop? in
            guard let place = places.first(where: { $0.name == name }) else { return nil }
            return Stop(waypoint: Waypoint(id: UUID().uuidString, name: place.name, coordinate: place.coordinate, placeId: place.id), dwellMinutes: 30 + (offset == 0 ? 15 : 0))
        }
        let title = ["草悟道晚風散步", "逢甲下班散步", "七期夜色散步", "美術園道小聚"][index]
        return RoutePlan(id: UUID().uuidString, title: title, origin: origin, stops: stops, endMode: .returnToOrigin, destination: nil, updatedAt: now)
    }
}
