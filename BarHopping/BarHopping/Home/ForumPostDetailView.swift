import SwiftUI

/// 文章詳細頁：全文、按讚、留言（留言只存在記憶體）。
struct ForumPostDetailView: View {
    let postID: ForumPost.ID
    let store: ForumStore
    @State private var draft = ""
    @FocusState private var isComposing: Bool

    var body: some View {
        Group {
            if let post = store.post(id: postID) {
                content(post)
            } else {
                ContentUnavailableView("找不到文章", systemImage: "doc.questionmark")
            }
        }
        .navigationTitle("文章")
        .navigationBarTitleDisplayMode(.inline)
        .background(HomeTheme.pageBackground)
    }

    private func content(_ post: ForumPost) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    ForumAuthorLine(author: post.author, date: post.createdAt, category: post.category)
                    Text(post.title).font(.title3.bold())
                    Text(post.body).font(.body)
                    if let route = post.route { ForumRouteBadge(route: route) }
                    ForumTagLine(tags: post.tags)
                    Divider()
                    HStack(spacing: 20) {
                        Button {
                            store.toggleLike(id: post.id)
                        } label: {
                            Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(post.isLiked ? HomeTheme.accent : .primary)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: post.isLiked)
                        .accessibilityLabel(post.isLiked ? "取消讚" : "按讚")
                        .accessibilityValue("\(post.likeCount) 個讚")

                        Label("\(post.commentCount) 則留言", systemImage: "bubble.right")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
                .homeCard()

                Text("留言 \(post.commentCount)")
                    .font(.headline)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)

                if post.comments.isEmpty {
                    Text("還沒有留言，來當第一個吧")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .homeCard()
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(post.comments) { comment in
                            commentRow(comment)
                            if comment.id != post.comments.last?.id { Divider().padding(.leading, 46) }
                        }
                    }
                    .homeCard(padding: 12)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { composer(post) }
    }

    private func commentRow(_ comment: ForumComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            InitialsAvatar(initials: comment.author.initials, colorIndex: comment.author.colorIndex, size: 34)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.author.name).font(.subheadline.weight(.semibold))
                    Text(HomeTheme.relative(comment.createdAt)).font(.caption).foregroundStyle(.secondary)
                }
                Text(comment.body).font(.subheadline)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func composer(_ post: ForumPost) -> some View {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        return HStack(alignment: .bottom, spacing: 8) {
            TextField("留言…", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($isComposing)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 18))
                .accessibilityLabel("輸入留言")
            Button {
                store.addComment(draft, to: post.id)
                draft = ""
                isComposing = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(trimmed.isEmpty ? Color.secondary : HomeTheme.accent)
            }
            .disabled(trimmed.isEmpty)
            .accessibilityLabel("送出留言")
        }
        .padding(.horizontal).padding(.vertical, 8)
        .background(.bar)
    }
}
