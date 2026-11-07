import SwiftUI

/// 首頁分頁根畫面：上半部個人化（草稿、統計），下半部論壇。
struct HomeTabView: View {
    @Environment(PlannerStore.self) private var planner
    @Environment(AppRouter.self) private var router

    @State private var forum = ForumStore()
    @State private var notifications = NotificationsStore()
    @State private var category: ForumCategory?
    @State private var drafts: [SavedDraft] = []
    @State private var draftError: String?
    @State private var pendingDraft: SavedDraft?
    @State private var isComposing = false
    @State private var showsDrinkPass = false

    private struct PostRoute: Hashable { let id: ForumPost.ID }
    private enum HomeRoute: Hashable { case notifications }

    private static let recentDraftLimit = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    HomeGreetingHeader()
                        .padding(.horizontal)

                    if !planner.plan.stops.isEmpty || !drafts.isEmpty || draftError != nil {
                        HomePlanSection(
                            plan: planner.plan, drafts: drafts, draftError: draftError,
                            onContinueCurrent: { router.selectedTab = .run },
                            onOpenDraft: requestLoad)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HomeSectionHeader("跑吧統計")
                        HomeStatsRow()
                            .padding(.horizontal)
                    }

                    DrinkPassBanner(event: DrinkPassMockData.event) { showsDrinkPass = true }
                        .padding(.horizontal)

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
                // 狀態列使用固定深色底，避免捲動內容降低時間和電量的對比。
                Color.clear.frame(height: 0)
                    .background(AppTheme.background.ignoresSafeArea(edges: .top))
            }
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("新增貼文", systemImage: "plus") { isComposing = true }
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("新增貼文")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: HomeRoute.notifications) {
                        Label("通知", systemImage: notifications.unreadCount > 0 ? "bell.badge" : "bell")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(notifications.unreadCount > 0 ? "通知，\(notifications.unreadCount) 則未讀" : "通知，沒有未讀")
                }
            }
            .navigationTitle("首頁")
            .navigationDestination(for: HomeRoute.self) { _ in
                NotificationsView(store: notifications)
            }
            .navigationDestination(for: PostRoute.self) { route in
                ForumPostDetailView(postID: route.id, store: forum)
            }
            .navigationDestination(isPresented: $showsDrinkPass) {
                DrinkPassDetailView(event: DrinkPassMockData.event)
            }
            .sheet(isPresented: $isComposing) {
                ForumComposeView(store: forum)
                    .presentationBackground(AppTheme.background)
            }
            .confirmationDialog("要載入這份草稿嗎？", isPresented: isConfirming, titleVisibility: .visible,
                                presenting: pendingDraft) { draft in
                Button("載入草稿", role: .destructive) { open(draft) }
                Button("取消", role: .cancel) {}
            } message: { _ in
                Text("目前路線「\(planner.plan.title)」還沒儲存的修改會消失。")
            }
        }
        .foregroundStyle(AppTheme.textPrimary)
        .tint(AppTheme.accentOnDark)
        .preferredColorScheme(.dark)
    }

    // MARK: - 論壇

    private var forumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader("論壇")

            Text("未滿 18 歲請勿飲酒｜喝酒不開車")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
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
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
                        .homeCard()
                } else if forum.posts.isEmpty, forum.isLoading {
                    ProgressView("載入中…").frame(maxWidth: .infinity).padding()
                } else if posts.isEmpty {
                    Text("這個分類還沒有文章，來發第一篇吧")
                        .font(.subheadline).foregroundStyle(AppTheme.textSecondary)
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

    private var isConfirming: Binding<Bool> {
        Binding(get: { pendingDraft != nil }, set: { if !$0 { pendingDraft = nil } })
    }

    private func requestLoad(_ draft: SavedDraft) {
        if !planner.hasUnsavedChanges || planner.plan.id == draft.plan.id {
            open(draft)
        } else {
            pendingDraft = draft
        }
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
        .environment(DrinkPassStore())
        .environment(AppRouter())
        .environment(UserProfileStore())
        .environment(PlannerStore(api: AppEnvironment.makeAPI(), drafts: AppEnvironment.makeDraftStore()))
}
