import Foundation
import SwiftUI

struct CreateGroupSheet: View {
    let onCreated: (UUID) -> Void
    @Environment(GroupsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var introduction = ""
    @State private var isPublic = true
    @State private var drinkLevel = GroupDrinkLevel.light
    @State private var selectedTags: Set<String> = []

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("團體名稱（必填）", text: $name)
                        .accessibilityLabel("團體名稱，必填")
                    TextField("介紹一下你的團體", text: $introduction, axis: .vertical)
                        .lineLimit(3...6).accessibilityLabel("團體簡介")
                } header: { Text("一起出發的小隊") }
                Section {
                    Toggle("公開團體", isOn: $isPublic)
                } footer: {
                    Text(isPublic ? "公開團體會出現在探索清單，任何人都可以加入。" : "私密團體不會出現在探索清單，建立後會產生一組邀請碼。")
                }
                Section {
                    Picker("喝酒程度（必選）", selection: $drinkLevel) {
                        ForEach(GroupDrinkLevel.allCases) { level in
                            Label(level.title, systemImage: level.symbol).tag(level)
                        }
                    }
                } header: {
                    Text("喝酒程度")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(drinkLevel.description)
                        if let reminder = drinkLevel.reminder { Text(reminder) }
                    }
                }
                Section("選擇標籤") {
                    ForEach(GroupsMockData.tags, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) { selectedTags.remove(tag) }
                            else { selectedTags.insert(tag) }
                        } label: {
                            HStack {
                                Text("#\(tag)").foregroundStyle(.primary)
                                Spacer()
                                if selectedTags.contains(tag) { Image(systemName: "checkmark.circle.fill") }
                            }.frame(minHeight: 32)
                        }
                        .accessibilityAddTraits(selectedTags.contains(tag) ? .isSelected : [])
                    }
                }
                Section {
                    Text("團體只保存在這次 App 工作階段，尚未提供帳號與多人同步。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("建立團體")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("建立") {
                        guard let id = store.create(name: name, introduction: introduction, isPublic: isPublic, drinkLevel: drinkLevel, tags: GroupsMockData.tags.filter { selectedTags.contains($0) }) else { return }
                        dismiss()
                        onCreated(id)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(AppTheme.accentOnDark)
    }
}
