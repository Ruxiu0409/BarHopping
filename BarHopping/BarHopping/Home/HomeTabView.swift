import SwiftUI

/// 首頁分頁根畫面：上半部個人化（任務、規劃入口、統計），下半部論壇。
struct HomeTabView: View {
    @Environment(PlannerStore.self) private var planner
    @Environment(AppRouter.self) private var router

    @State private var forum = ForumStore()
    @State private var category: ForumCategory?
    @State private var drafts: [SavedDraft] = []
    @State private var draftError: String?
    @State private var pendingAction: PendingPlanAction?
    @State private var isComposing = false

    private enum PendingPlanAction: Identifiable {
        case startNew
        case load(SavedDraft)
        var id: String {
            switch self {
            case .startNew: "new"
            case .load(let d): "load-\(d.id)"
            }
        }
    }

    private struct PostRoute: Hashable { let id: ForumPost.ID }

    private static let recentDraftLimit = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    HomeGreetingHeader(user: HomeMockProfile.user)
                        .padding(.horizontal)

                    HomePlanSection(
                        plan: planner.plan, drafts: drafts, draftError: draftError,
                        onStartNew: requestStartNew,
                        onContinueCurrent: { router.selectedTab = .run },
                        onOpenDraft: requestLoad)

                    VStack(alignment: .leading, spacing: 10) {
                        HomeSectionHeader("我的任務") {
                            Text("本週").font(.subheadline).foregroundStyle(.secondary)
                        }
                        HomeQuestSection(quests: HomeMockProfile.quests)
                        HomeSafetyTip(text: HomeMockProfile.safetyTip)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HomeSectionHeader("本月足跡")
                        HomeStatsRow(stats: HomeMockProfile.stats)
                            .padding(.horizontal)
                    }

                    forumSection
                }
                .padding(.vertical)
            }
            .background(HomeTheme.pageBackground)
            .refreshable {
                async let f: Void = forum.refresh()
                async let d: Void = loadDrafts()
                _ = await (f, d)
            }
            .task {
                async let f: Void = forum.loadIfNeeded()
                async let d: Void = loadDrafts()
                _ = await (f, d)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                // 導覽列隱藏時，讓狀態列底下有模糊背景，內容不會直接疊在時間和電量上。
                Color.clear.frame(height: 0).background(.bar)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle("首頁")
            .navigationDestination(for: PostRoute.self) { route in
                ForumPostDetailView(postID: route.id, store: forum)
            }
            .sheet(isPresented: $isComposing) {
                ForumComposeView(store: forum)
            }
            .confirmationDialog(confirmTitle, isPresented: isConfirming, titleVisibility: .visible,
                                presenting: pendingAction) { action in
                switch action {
                case .startNew:
                    Button("開始新規劃", role: .destructive) { startNew() }
                case .load(let draft):
                    Button("載入草稿", role: .destructive) { open(draft) }
                }
                Button("取消", role: .cancel) {}
            } message: { _ in
                Text("目前路線「\(planner.plan.title)」還沒儲存的修改會消失。")
            }
        }
    }

    // MARK: - 論壇

    private var forumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader("論壇") {
                Button {
                    isComposing = true
                } label: {
                    Label("發文", systemImage: "square.and.pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(HomeTheme.accent)
                }
                .accessibilityLabel("發新文章")
            }

            Text("未滿 18 歲請勿飲酒｜喝酒不開車")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    HomeChip(title: "全部", isSelected: category == nil) { category = nil }
                    ForEach(ForumCategory.allCases) { c in
                        HomeChip(title: c.title, isSelected: category == c) { category = c }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            let posts = forum.posts(in: category)
            Group {
                if let error = forum.errorMessage, forum.posts.isEmpty {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .homeCard()
                } else if forum.posts.isEmpty, forum.isLoading {
                    ProgressView("載入中…").frame(maxWidth: .infinity).padding()
                } else if posts.isEmpty {
                    Text("這個分類還沒有文章，來發第一篇吧")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .homeCard()
                } else {
                    ForEach(posts) { post in
                        NavigationLink(value: PostRoute(id: post.id)) {
                            ForumPostRow(post: post)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - 規劃入口

    private var confirmTitle: String {
        switch pendingAction {
        case .load: "要載入這份草稿嗎？"
        default: "要開始新的規劃嗎？"
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(get: { pendingAction != nil }, set: { if !$0 { pendingAction = nil } })
    }

    private func requestStartNew() {
        if planner.hasUnsavedChanges { pendingAction = .startNew } else { startNew() }
    }

    private func requestLoad(_ draft: SavedDraft) {
        if !planner.hasUnsavedChanges || planner.plan.id == draft.plan.id {
            open(draft)
        } else {
            pendingAction = .load(draft)
        }
    }

    private func startNew() {
        planner.startNewPlan()
        router.selectedTab = .map
    }

    private func open(_ draft: SavedDraft) {
        planner.load(draft)
        router.selectedTab = .run
    }

    private func showRecent(_ all: [SavedDraft]) {
        drafts = Array(all.sorted { $0.savedAt > $1.savedAt }.prefix(Self.recentDraftLimit))
    }

    private func loadDrafts() async {
        do {
            showRecent(try await planner.drafts.loadAll())
            draftError = nil
        } catch is CancellationError {
            return
        } catch let error as DraftLoadError {
            // 部分檔案損壞：照常顯示讀得到的草稿，損壞的檔案不動。
            showRecent(error.report.drafts)
            draftError = "有 \(error.report.failures.count) 份草稿讀不到，到路跑的已儲存路線查看"
        } catch {
            drafts = []
            draftError = "草稿暫時讀不到，下拉可以重試"
        }
    }
}

#Preview {
    HomeTabView()
        .environment(AppRouter())
        .environment(PlannerStore(api: AppEnvironment.makeAPI(), drafts: AppEnvironment.makeDraftStore()))
}
