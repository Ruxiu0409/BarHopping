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
        .foregroundStyle(AppTheme.textPrimary)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
    }

    private func content(_ post: ForumPost) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 14) {
                    ForumAuthorLine(author: post.author, date: post.createdAt, category: post.category)
                    Text(post.title).font(.title3.bold())
                    Text(post.body).font(.body)
                    ForumTagLine(tags: post.tags)
                    Divider()
                    HStack(spacing: 20) {
                        Button {
                            store.toggleLike(id: post.id)
                        } label: {
                            Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(post.isLiked ? HomeTheme.accent : AppTheme.textPrimary)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: post.isLiked)
                        .accessibilityLabel(post.isLiked ? "取消讚" : "按讚")
                        .accessibilityValue("\(post.likeCount) 個讚")

                        Label("\(post.commentCount) 則留言", systemImage: "bubble.right")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .font(.subheadline)
                }
                .homeCard()

                if let recipe = post.recipe {
                    ForumRecipeCard(recipe: recipe)
                }

                Text("留言 \(post.commentCount)")
                    .font(.headline)
                    .padding(.horizontal, 4)
                    .accessibilityAddTraits(.isHeader)

                if post.comments.isEmpty {
                    Text("還沒有留言，來當第一個吧")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
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
                    Text(HomeTheme.relative(comment.createdAt)).font(.caption).foregroundStyle(AppTheme.textSecondary)
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
                .background(AppTheme.elevated, in: .rect(cornerRadius: 18))
                .accessibilityLabel("輸入留言")
            Button {
                store.addComment(draft, to: post.id)
                draft = ""
                isComposing = false
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(trimmed.isEmpty ? AppTheme.textSecondary : HomeTheme.accent)
            }
            .disabled(trimmed.isEmpty)
            .accessibilityLabel("送出留言")
        }
        .padding(.horizontal).padding(.vertical, 8)
        .background(AppTheme.surface)
    }
}

/// 詳細頁的酒譜：摘要、材料清單、編號步驟。
struct ForumRecipeCard: View {
    let recipe: ForumRecipe

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("酒譜", systemImage: "wineglass")
                    .font(.headline)
                    .foregroundStyle(HomeTheme.accent)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if !recipe.containsAlcohol {
                    Text("無酒精")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.success)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(AppTheme.success.opacity(0.12), in: .capsule)
                }
            }

            summary

            VStack(alignment: .leading, spacing: 8) {
                Text("材料").font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                ForEach(recipe.ingredients) { item in
                    HStack(alignment: .firstTextBaseline) {
                        Circle().fill(HomeTheme.accent).frame(width: 6, height: 6)
                            .alignmentGuide(.firstTextBaseline) { $0[.bottom] }
                            .accessibilityHidden(true)
                        Text(item.name)
                        Spacer(minLength: 12)
                        Text(item.amount)
                            .foregroundStyle(AppTheme.textSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.subheadline)
                    .accessibilityElement(children: .combine)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("步驟").font(.subheadline.weight(.semibold)).accessibilityAddTraits(.isHeader)
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(HomeTheme.accent, in: .circle)
                            .accessibilityHidden(true)
                        Text(step)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("第 \(index + 1) 步，\(step)")
                }
            }

            if recipe.containsAlcohol {
                Text("未滿 18 歲請勿飲酒｜喝酒不開車｜慢慢喝、多喝水")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .homeCard()
    }

    private var summary: some View {
        let items: [(String, String, String)] = [
            ("chart.bar", "難度", recipe.difficulty.title),
            ("dollarsign.circle", "花費", recipe.estimatedCost),
            ("cart", "哪裡買", recipe.sources.map(\.title).joined(separator: "、")),
        ]
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { summaryItems(items) }
            VStack(alignment: .leading, spacing: 8) { summaryItems(items) }
        }
    }

    private func summaryItems(_ items: [(String, String, String)]) -> some View {
        ForEach(items, id: \.1) { icon, label, value in
            VStack(alignment: .leading, spacing: 2) {
                Label(label, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .fixedSize()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.elevated, in: .rect(cornerRadius: 10))
            .accessibilityElement(children: .combine)
        }
    }
}
