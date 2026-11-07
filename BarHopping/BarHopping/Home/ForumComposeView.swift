import SwiftUI

/// 發新文章（只存在記憶體）。
struct ForumComposeView: View {
    let store: ForumStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var category: ForumCategory = .routeShare
    @State private var tagsText = ""

    private var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("分類") {
                    Picker("分類", selection: $category) {
                        ForEach(ForumCategory.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("標題") {
                    TextField("例如：草悟道散步三站路線", text: $title)
                }
                Section("內文") {
                    TextField("分享你的路線、店家心得或問題…", text: $bodyText, axis: .vertical)
                        .lineLimit(5...12)
                }
                Section {
                    TextField("#西區 #草悟道", text: $tagsText)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("標籤（選填）")
                } footer: {
                    Text("用空白分隔。請友善發言，不鼓勵拚酒，喝酒不開車。")
                }
            }
            .navigationTitle("發新文章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("發佈") {
                        store.addPost(title: title, body: bodyText, category: category, tags: parsedTags)
                        dismiss()
                    }
                    .disabled(!canPost)
                }
            }
        }
    }

    private var parsedTags: [String] {
        tagsText.split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "，" })
            .map { $0.hasPrefix("#") ? String($0) : "#" + $0 }
            .filter { $0.count > 1 }
    }
}
