import Foundation
import Observation

@MainActor @Observable
final class GroupsStore {
    private(set) var groups: [SocialGroup]

    init(groups: [SocialGroup]? = nil) {
        self.groups = groups ?? GroupsMockData.makeGroups()
    }

    var myGroups: [SocialGroup] { groups.filter(\.isJoined) }
    func group(_ id: UUID) -> SocialGroup? { groups.first { $0.id == id } }
    func event(groupID: UUID, eventID: UUID) -> GroupEvent? {
        group(groupID)?.events.first { $0.id == eventID }
    }
    func explore(drinkLevel: GroupDrinkLevel?) -> [SocialGroup] {
        groups.filter { $0.isPublic && (drinkLevel == nil || $0.drinkLevel == drinkLevel) }
    }

    func join(_ id: UUID) {
        guard let i = groups.firstIndex(where: { $0.id == id }), !groups[i].isJoined else { return }
        groups[i].members.append(GroupMember(id: GroupMember.currentID, nickname: "我", isAdmin: false))
        groups[i].lastActiveAt = .now
    }

    func leave(_ id: UUID) {
        guard let i = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[i].members.removeAll { $0.id == GroupMember.currentID }
        for j in groups[i].events.indices {
            groups[i].events[j].participantIDs.remove(GroupMember.currentID)
        }
        groups[i].lastActiveAt = .now
    }

    func join(inviteCode: String) -> UUID? {
        let code = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard let group = groups.first(where: { $0.inviteCode == code }) else { return nil }
        join(group.id)
        return group.id
    }

    @discardableResult
    func create(name: String, introduction: String, isPublic: Bool, drinkLevel: GroupDrinkLevel, tags: [String]) -> UUID? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        let id = UUID()
        var code: String
        repeat { code = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)) }
        while groups.contains(where: { $0.inviteCode == code })
        groups.insert(SocialGroup(id: id, name: name, introduction: introduction.trimmingCharacters(in: .whitespacesAndNewlines), isPublic: isPublic, drinkLevel: drinkLevel, tags: tags, symbol: "person.3.fill", inviteCode: code, members: [GroupMember(id: GroupMember.currentID, nickname: "我", isAdmin: true)], lastActiveAt: .now, events: [], messages: []), at: 0)
        return id
    }

    func toggleParticipation(groupID: UUID, eventID: UUID) {
        guard let i = groups.firstIndex(where: { $0.id == groupID }), groups[i].isJoined,
              let j = groups[i].events.firstIndex(where: { $0.id == eventID }) else { return }
        if groups[i].events[j].isParticipating { groups[i].events[j].participantIDs.remove(GroupMember.currentID) }
        else { groups[i].events[j].participantIDs.insert(GroupMember.currentID) }
        groups[i].lastActiveAt = .now
    }

    @discardableResult
    func createEvent(groupID: UUID, title: String, date: Date, meetingPoint: String, plan: RoutePlan, distance: Double?) -> Bool {
        guard let i = groups.firstIndex(where: { $0.id == groupID }), groups[i].isJoined,
              !plan.stops.isEmpty, date > .now,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !meetingPoint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        groups[i].events.append(GroupEvent(id: UUID(), title: title.trimmingCharacters(in: .whitespacesAndNewlines), date: date, meetingPoint: meetingPoint.trimmingCharacters(in: .whitespacesAndNewlines), plan: plan, distanceMeters: distance, participantIDs: [GroupMember.currentID]))
        groups[i].lastActiveAt = .now
        return true
    }

    func post(_ text: String, groupID: UUID) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let i = groups.firstIndex(where: { $0.id == groupID }), groups[i].isJoined else { return }
        groups[i].messages.append(GroupMessage(id: UUID(), author: "我", text: text, date: .now, isAnnouncement: false))
        groups[i].lastActiveAt = .now
    }
}
