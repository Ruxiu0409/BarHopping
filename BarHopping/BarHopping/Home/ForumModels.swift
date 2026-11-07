import Foundation

/// 論壇分類（「全部」以 nil 表示）。
enum ForumCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case convenience, classic, nonAlcoholic, technique, newbie

    var id: Self { self }

    var title: String {
        switch self {
        case .convenience: "超商調酒"
        case .classic: "經典調酒"
        case .nonAlcoholic: "無酒精"
        case .technique: "技巧器材"
        case .newbie: "新手問題"
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

/// 酒譜材料，例如「檸檬紅茶」「200ml」。
struct RecipeIngredient: Identifiable, Hashable, Sendable {
    var id = UUID().uuidString
    var name: String
    var amount: String
}

enum RecipeDifficulty: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case easy = 1, medium, hard

    var id: Self { self }

    var title: String {
        switch self {
        case .easy: "簡單"
        case .medium: "普通"
        case .hard: "進階"
        }
    }
}

/// 材料在哪裡買得到。
enum RecipeSource: String, CaseIterable, Identifiable, Hashable, Sendable {
    case convenienceStore, supermarket, liquorStore

    var id: Self { self }

    var title: String {
        switch self {
        case .convenienceStore: "超商"
        case .supermarket: "超市"
        case .liquorStore: "酒行"
        }
    }
}

/// 文章附帶的酒譜。
struct ForumRecipe: Hashable, Sendable {
    var ingredients: [RecipeIngredient]
    var steps: [String]
    var difficulty: RecipeDifficulty
    /// 顯示用花費，例如「約 NT$120」。
    var estimatedCost: String
    var sources: [RecipeSource]
    var containsAlcohol: Bool
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
    var recipe: ForumRecipe?

    var commentCount: Int { comments.count }
}
