import Foundation
import Observation

/// 論壇資料來源。之後接真的 API 時只要換掉實作。
protocol ForumDataSource {
    func fetchPosts() async throws -> [ForumPost]
}

struct MockForumDataSource: ForumDataSource {
    func fetchPosts() async throws -> [ForumPost] {
        try await Task.sleep(for: .milliseconds(300))
        return ForumMockData.posts(now: .now)
    }
}

/// 首頁論壇狀態。按讚、留言、發文目前只存在記憶體。
@MainActor @Observable
final class ForumStore {
    private(set) var posts: [ForumPost] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private var hasLoaded = false

    /// 目前登入的使用者（mock）。
    let currentUser: ForumAuthor
    private let source: ForumDataSource

    init(source: ForumDataSource = MockForumDataSource(),
         currentUser: ForumAuthor = HomeMockProfile.user.forumAuthor) {
        self.source = source
        self.currentUser = currentUser
    }

    func posts(in category: ForumCategory?) -> [ForumPost] {
        guard let category else { return posts }
        return posts.filter { $0.category == category }
    }

    func post(id: ForumPost.ID) -> ForumPost? { posts.first { $0.id == id } }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await source.fetchPosts()
            // 保留本機新增的文章（mock 階段沒有伺服器可以存）。
            let fetchedIDs = Set(fetched.map(\.id))
            let local = posts.filter { $0.author == currentUser && !fetchedIDs.contains($0.id) }
            posts = (local + fetched).sorted { $0.createdAt > $1.createdAt }
            errorMessage = nil
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "無法載入論壇，請下拉重新整理"
        }
    }

    func toggleLike(id: ForumPost.ID) {
        guard let i = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[i].isLiked.toggle()
        posts[i].likeCount += posts[i].isLiked ? 1 : -1
    }

    func addComment(_ text: String, to id: ForumPost.ID) {
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty, let i = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[i].comments.append(ForumComment(author: currentUser, body: body, createdAt: .now))
    }

    func addPost(title: String, body: String, category: ForumCategory, tags: [String]) {
        let post = ForumPost(author: currentUser, createdAt: .now, category: category,
                             title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                             body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                             tags: tags, likeCount: 0)
        posts.insert(post, at: 0)
    }
}
