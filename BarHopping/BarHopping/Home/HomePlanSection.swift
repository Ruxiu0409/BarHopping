import SwiftUI

/// 目前路線與最近草稿的繼續編輯入口。
struct HomePlanSection: View {
    let plan: RoutePlan
    let drafts: [SavedDraft]
    let draftError: String?
    let onContinueCurrent: () -> Void
    let onOpenDraft: (SavedDraft) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if !plan.stops.isEmpty {
                Button(action: onContinueCurrent) {
                    planRow(icon: "pencil.and.list.clipboard", eyebrow: "繼續編輯目前路線",
                            title: plan.title, detail: "\(plan.stops.count) 站")
                }
                .buttonStyle(.plain)
                .accessibilityHint("前往路跑分頁")
            }

            if let draftError {
                Label(draftError, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            if !drafts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("最近的草稿")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .padding(.horizontal, 4)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(drafts) { draft in
                        Button { onOpenDraft(draft) } label: {
                            planRow(icon: "doc.text", eyebrow: nil, title: draft.plan.title,
                                    detail: draftDetail(draft))
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("載入草稿並前往路跑分頁")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func draftDetail(_ draft: SavedDraft) -> String {
        var parts = ["\(draft.plan.stops.count) 站"]
        if let r = draft.result { parts.append(Fmt.distance(r.distanceMeters)) }
        parts.append("儲存於 \(HomeTheme.relative(draft.savedAt))")
        return parts.joined(separator: " · ")
    }

    private func planRow(icon: String, eyebrow: String?, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(HomeTheme.accentOnDark)
                .frame(width: 36, height: 36)
                .background(AppTheme.accentSoft, in: .rect(cornerRadius: 10))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                if let eyebrow {
                    Text(eyebrow).font(.caption.weight(.semibold)).foregroundStyle(HomeTheme.accentOnDark)
                }
                Text(title).font(.headline).foregroundStyle(AppTheme.textPrimary).lineLimit(2)
                Text(detail).font(.footnote).foregroundStyle(AppTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .accessibilityHidden(true)
        }
        .homeCard(padding: 12)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
