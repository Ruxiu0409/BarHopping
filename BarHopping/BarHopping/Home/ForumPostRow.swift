import SwiftUI

/// 論壇列表的一篇文章卡片。
struct ForumPostRow: View {
    let post: ForumPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForumAuthorLine(author: post.author, date: post.createdAt, category: post.category)

            Text(post.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Text(post.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if let route = post.route { ForumRouteBadge(route: route) }

            ForumTagLine(tags: post.tags)

            HStack(spacing: 16) {
                Label("\(post.likeCount)", systemImage: post.isLiked ? "heart.fill" : "heart")
                    .foregroundStyle(post.isLiked ? HomeTheme.accent : .secondary)
                Label("\(post.commentCount)", systemImage: "bubble.right")
                    .foregroundStyle(.secondary)
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
        if let r = post.route { parts.append("附路線 \(r.stopCount) 站，\(Fmt.distance(r.distanceMeters))") }
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
                Text(HomeTheme.relative(date)).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let category {
                Text(category.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HomeTheme.accent)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(HomeTheme.accent.opacity(0.1), in: .capsule)
            }
        }
    }
}

struct ForumRouteBadge: View {
    let route: ForumRouteSummary

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                .foregroundStyle(HomeTheme.accent)
            Text("\(route.stopCount) 站 · \(Fmt.distance(route.distanceMeters)) · 步行 \(Fmt.duration(route.walkingSeconds))")
        }
        .font(.footnote)
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
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
