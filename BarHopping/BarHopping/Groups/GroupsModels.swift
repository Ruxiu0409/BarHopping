import Foundation

struct SocialGroup: Identifiable {
    let id: UUID
    var name: String
    var introduction: String
    var isPublic: Bool
    var drinkLevel: GroupDrinkLevel
    var tags: [String]
    var symbol: String
    var inviteCode: String
    var members: [GroupMember]
    var lastActiveAt: Date
    var events: [GroupEvent]
    var messages: [GroupMessage]

    var isJoined: Bool { members.contains { $0.id == GroupMember.currentID } }
    var nextEvent: GroupEvent? {
        events.filter { $0.date >= .now }.min { $0.date < $1.date }
    }
}

struct GroupMember: Identifiable {
    static let currentID = "local-me"
    let id: String
    var nickname: String
    var isAdmin: Bool
    var role: String { isAdmin ? "管理員" : "成員" }
}

struct GroupEvent: Identifiable {
    let id: UUID
    var title: String
    var date: Date
    var meetingPoint: String
    var plan: RoutePlan
    var distanceMeters: Double?
    var participantIDs: Set<String>
    var isParticipating: Bool { participantIDs.contains(GroupMember.currentID) }
}

struct GroupMessage: Identifiable {
    let id: UUID
    var author: String
    var text: String
    var date: Date
    var isAnnouncement: Bool
}

enum GroupsDestination: Hashable {
    case group(UUID)
    case event(groupID: UUID, eventID: UUID)
}
