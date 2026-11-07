import SwiftUI

/// 論壇列表的一篇文章卡片。
struct ForumPostRow: View {
    let post: ForumPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForumAuthorLine(author: post.author, date: post.createdAt, category: post.category)

            Text(post.title)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)

            Text(post.body)
                .font(.subheadline)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let recipe = post.recipe { ForumRecipeBadges(recipe: recipe) }

            ForumTagLine(tags: post.tags)

            HStack(spacing: 16) {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLiked ? HomeTheme.accent : AppTheme.textSecondary)
                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .font(.footnote)
        }
        .homeCard()
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("開啟文章")
    }

    private var accessibilityText: String {
        var parts = ["\(post.category.title)", post.title, "\(post.author.name)，\(HomeTheme.relative(post.createdAt))"]
        if let r = post.recipe { parts.append("附酒譜，\(r.ingredients.count) 種材料，\(r.estimatedCost)，難度\(r.difficulty.title)\(r.containsAlcohol ? "" : "，無酒精")") }
        parts.append("\(post.likeCount) 個讚\(post.isLiked ? "，已按讚" : "")，\(post.commentCount) 則留言")
        return parts.joined(separator: "，")
    }
}

struct ForumAuthorLine: View {
    let author: ForumAuthor
    let date: Date
    var category: ForumCategory?

    var body: some View {
        HStack(spacing: 10) {
            InitialsAvatar(initials: author.initials, colorIndex: author.colorIndex, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(author.name).font(.subheadline.weight(.semibold))
                Text(HomeTheme.relative(date)).font(.caption).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 8)
            if let category {
                Text(category.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HomeTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(AppTheme.accentSoft, in: .capsule)
            }
        }
    }
}

/// 酒譜小標籤：材料數、花費、難度。
struct ForumRecipeBadges: View {
    let recipe: ForumRecipe

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 6) { badges }
            VStack(alignment: .leading, spacing: 6) { badges }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var badges: some View {
        badge("\(recipe.ingredients.count) 種材料", systemImage: "list.bullet")
        badge(recipe.estimatedCost, systemImage: "dollarsign.circle")
        badge(recipe.difficulty.title, systemImage: "chart.bar")
        if !recipe.containsAlcohol {
            badge("無酒精", systemImage: "leaf", tint: AppTheme.success)
        }
    }

    private func badge(_ text: String, systemImage: String, tint: Color = HomeTheme.accent) -> some View {
        Label {
            Text(text).foregroundStyle(AppTheme.textPrimary)
        } icon: {
            Image(systemName: systemImage).foregroundStyle(tint)
        }
        .font(.caption)
        .lineLimit(1)
        .padding(.horizontal, 8).padding(.vertical, 5)
        .background(AppTheme.elevated, in: .capsule)
    }
}

struct ForumTagLine: View {
    let tags: [String]

    var body: some View {
        if !tags.isEmpty {
            Text(tags.joined(separator: "  "))
                .font(.footnote)
                .foregroundStyle(HomeTheme.accent)
                .lineLimit(2)
        }
    }
}
