import Foundation

/// 論壇分類（「全部」以 nil 表示）。
enum ForumCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case routeShare, venueReview, meetup, newbie

    var id: Self { self }

    var title: String {
        switch self {
        case .routeShare: "路線分享"
        case .venueReview: "店家心得"
        case .meetup: "揪團"
        case .newbie: "新手問題"
        }
    }

    var systemImage: String {
        switch self {
        case .routeShare: "point.topleft.down.to.point.bottomright.curvepath"
        case .venueReview: "star.bubble"
        case .meetup: "person.2"
        case .newbie: "questionmark.circle"
        }
    }
}

struct ForumAuthor: Hashable, Sendable {
    var name: String
    var initials: String
    var colorIndex: Int
}

struct ForumComment: Identifiable, Hashable, Sendable {
    var id = UUID().uuidString
    var author: ForumAuthor
    var body: String
    var createdAt: Date
}

/// 文章附帶的路線摘要。
struct ForumRouteSummary: Hashable, Sendable {
    var stopCount: Int
    var distanceMeters: Double
    var walkingSeconds: Double
}

struct ForumPost: Identifiable, Hashable, Sendable {
    var id = UUID().uuidString
    var author: ForumAuthor
    var createdAt: Date
    var category: ForumCategory
    var title: String
    var body: String
    var tags: [String]
    var likeCount: Int
    var isLiked = false
    var comments: [ForumComment] = []
    var route: ForumRouteSummary?

    var commentCount: Int { comments.count }
}
