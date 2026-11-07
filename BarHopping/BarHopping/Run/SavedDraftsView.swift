import SwiftUI

/// 已儲存的路線清單。讀取失敗時只顯示錯誤，不覆寫或刪除任何資料。
struct SavedDraftsView: View {
    let drafts: DraftStoring
    let currentPlanId: String
    let hasUnsavedChanges: Bool
    let onLoad: (SavedDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    private enum LoadState {
        case loading
        /// failures：讀取失敗的檔案說明（DraftLoadError），成功的草稿照常顯示。
        case loaded([SavedDraft], failures: [String])
        case failed(String)
    }

    @State private var state: LoadState = .loading
    @State private var pendingLoad: SavedDraft?
    @State private var pendingDelete: SavedDraft?
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            content
                .scrollContentBackground(.hidden)
                .background(AppTheme.background)
                .foregroundStyle(AppTheme.textPrimary)
                .toolbarBackground(AppTheme.background, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                .navigationTitle("已儲存的路線")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("關閉") { dismiss() }
                    }
                }
                .task { await reload() }
                .refreshable { await reload() }
                .confirmationDialog("目前的規劃有未儲存的變更", isPresented: isPresented($pendingLoad),
                                    titleVisibility: .visible, presenting: pendingLoad) { draft in
                    Button("捨棄變更並載入「\(draft.plan.title)」", role: .destructive) { load(draft) }
                    Button("取消", role: .cancel) {}
                } message: { _ in
                    Text("載入後，目前規劃中未儲存的內容會消失。")
                }
                .confirmationDialog("刪除這條路線？", isPresented: isPresented($pendingDelete),
                                    titleVisibility: .visible, presenting: pendingDelete) { draft in
                    Button("刪除「\(draft.plan.title)」", role: .destructive) {
                        Task { await delete(draft) }
                    }
                    Button("取消", role: .cancel) {}
                } message: { _ in
                    Text("刪除後無法復原。")
                }
                .alert("刪除失敗", isPresented: isPresented($deleteError)) {
                    Button("好", role: .cancel) {}
                } message: {
                    Text(deleteError ?? "")
                }
        }
        .tint(RunTheme.accent)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            ProgressView("載入中…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message):
            ContentUnavailableView {
                Label("載入失敗", systemImage: "exclamationmark.triangle")
            } description: {
                Text("已儲存的路線無法讀取，原始資料沒有被修改。\n\(message)")
            } actions: {
                Button("重新載入") { Task { await reload() } }
                    .buttonStyle(.borderedProminent)
            }
        case .loaded(let items, let failures) where items.isEmpty && failures.isEmpty:
            ContentUnavailableView("還沒有儲存的路線", systemImage: "bookmark",
                                   description: Text("在路跑頁按「儲存」就會出現在這裡。"))
        case .loaded(let items, let failures):
            List {
                Group {
                    if !failures.isEmpty {
                        Section {
                            ForEach(failures, id: \.self) { message in
                                Label(message, systemImage: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundStyle(AppTheme.danger)
                            }
                        } header: {
                            Text("載入失敗")
                        } footer: {
                            Text("這些檔案無法讀取，原始資料沒有被刪除或覆寫。")
                        }
                    }
                    if items.isEmpty {
                        Text("沒有可載入的路線")
                            .foregroundStyle(AppTheme.textSecondary)
                    } else {
                        Section {
                            ForEach(items) { draft in
                                row(draft)
                            }
                        }
                    }
                }
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.separator)
            }
        }
    }

    private func row(_ draft: SavedDraft) -> some View {
        HStack(spacing: 12) {
            Button {
                requestLoad(draft)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(draft.plan.title).font(.headline)
                        if draft.id == currentPlanId {
                            Text("目前").font(.caption.bold()).foregroundStyle(RunTheme.accent)
                        }
                    }
                    Text(summary(draft))
                        .font(.footnote)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("儲存於 \(draft.savedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("載入 \(draft.plan.title)")
            .accessibilityHint(summary(draft))

            Button(role: .destructive) {
                pendingDelete = draft
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .tint(AppTheme.danger)
            .accessibilityLabel("刪除 \(draft.plan.title)")
        }
        .swipeActions {
            Button("刪除", role: .destructive) { pendingDelete = draft }
        }
    }

    private func summary(_ draft: SavedDraft) -> String {
        var parts = ["\(draft.plan.stops.count) 間酒吧"]
        parts.append(draft.plan.endMode == .returnToOrigin ? "回到起點" : "自訂終點")
        if let r = draft.result {
            parts.append(Fmt.distance(r.distanceMeters))
            parts.append(Fmt.duration(r.totalDurationSeconds))
        }
        return parts.joined(separator: " · ")
    }

    private func requestLoad(_ draft: SavedDraft) {
        if hasUnsavedChanges { pendingLoad = draft } else { load(draft) }
    }

    private func load(_ draft: SavedDraft) {
        onLoad(draft)
        dismiss()
    }

    private func reload() async {
        do {
            let items = try await drafts.loadAll()
            state = .loaded(items.sorted { $0.savedAt > $1.savedAt }, failures: [])
        } catch let e as DraftLoadError {
            state = .loaded(e.report.drafts.sorted { $0.savedAt > $1.savedAt },
                            failures: e.failures.map(\.message))
        } catch let e as ServiceError {
            state = .failed(e.message)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func delete(_ draft: SavedDraft) async {
        do {
            try await drafts.delete(id: draft.id)
            await reload()
        } catch {
            deleteError = (error as? ServiceError)?.message ?? error.localizedDescription
        }
    }

    private func isPresented<T>(_ binding: Binding<T?>) -> Binding<Bool> {
        Binding(get: { binding.wrappedValue != nil },
                set: { if !$0 { binding.wrappedValue = nil } })
    }
}
