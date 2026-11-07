import SwiftUI

/// 發新文章，可選擇附上酒譜（只存在記憶體）。
struct ForumComposeView: View {
    let store: ForumStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var bodyText = ""
    @State private var category: ForumCategory = .convenience
    @State private var tagsText = ""

    // 酒譜
    @State private var includesRecipe = true
    @State private var ingredients: [RecipeIngredient] = [RecipeIngredient(name: "", amount: "")]
    @State private var steps: [EditableStep] = [EditableStep()]
    @State private var difficulty: RecipeDifficulty = .easy
    @State private var cost = ""
    @State private var sources: Set<RecipeSource> = [.convenienceStore]
    @State private var containsAlcohol = true

    private struct EditableStep: Identifiable {
        let id = UUID()
        var text = ""
    }

    private func trimmed(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var filledIngredients: [RecipeIngredient] {
        ingredients.filter { !trimmed($0.name).isEmpty }
            .map { RecipeIngredient(name: trimmed($0.name), amount: trimmed($0.amount)) }
    }

    private var filledSteps: [String] { steps.map { trimmed($0.text) }.filter { !$0.isEmpty } }

    private var recipeIsValid: Bool { !filledIngredients.isEmpty && !filledSteps.isEmpty }

    private var canPost: Bool {
        !trimmed(title).isEmpty && !trimmed(bodyText).isEmpty && (!includesRecipe || recipeIsValid)
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    Section("分類") {
                        Picker("分類", selection: $category) {
                            ForEach(ForumCategory.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.menu)
                    }
                    Section("標題") {
                        TextField("例如：檸檬紅茶＋伏特加十分鐘上手", text: $title)
                    }
                    Section("內文") {
                        TextField("分享你的調法、心得或問題…", text: $bodyText, axis: .vertical)
                            .lineLimit(4...10)
                    }

                    Section {
                        Toggle("附上酒譜", isOn: $includesRecipe.animation())
                            .tint(HomeTheme.accentOnDark)
                    } footer: {
                        if includesRecipe && !recipeIsValid {
                            Text("至少填一項材料和一個步驟才能發佈。")
                        }
                    }

                    if includesRecipe { recipeSections }

                    Section {
                        TextField("#超商調酒 #十分鐘上手", text: $tagsText)
                            .textInputAutocapitalization(.never)
                    } header: {
                        Text("標籤（選填）")
                    } footer: {
                        Text("用空白分隔。未滿 18 歲請勿飲酒，喝酒不開車；份量適中，不鼓勵拚酒。")
                    }
                }
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.separator)
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .foregroundStyle(AppTheme.textPrimary)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .navigationTitle("發新文章")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("發佈") { post() }
                        .disabled(!canPost)
                }
            }
        }
        .tint(AppTheme.accentOnDark)
        .preferredColorScheme(.dark)
    }

    @ViewBuilder private var recipeSections: some View {
        Section("材料") {
            ForEach($ingredients) { $item in
                HStack {
                    TextField("品名，例如 檸檬紅茶", text: $item.name)
                    TextField("份量", text: $item.amount)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 110)
                    removeButton(label: "刪除材料 \(item.name)", disabled: ingredients.count <= 1) {
                        ingredients.removeAll { $0.id == item.id }
                    }
                }
            }
            .onDelete { offsets in
                guard ingredients.count > offsets.count else { return }
                ingredients.remove(atOffsets: offsets)
            }
            Button {
                ingredients.append(RecipeIngredient(name: "", amount: ""))
            } label: {
                Label("新增材料", systemImage: "plus.circle.fill")
            }
            .tint(HomeTheme.accentOnDark)
        }

        Section("步驟") {
            ForEach(Array($steps.enumerated()), id: \.element.id) { index, $step in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(index + 1).")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(AppTheme.textSecondary)
                        .accessibilityHidden(true)
                    TextField("第 \(index + 1) 步", text: $step.text, axis: .vertical)
                    removeButton(label: "刪除第 \(index + 1) 步", disabled: steps.count <= 1) {
                        steps.removeAll { $0.id == step.id }
                    }
                }
            }
            .onDelete { offsets in
                guard steps.count > offsets.count else { return }
                steps.remove(atOffsets: offsets)
            }
            Button {
                steps.append(EditableStep())
            } label: {
                Label("新增步驟", systemImage: "plus.circle.fill")
            }
            .tint(HomeTheme.accentOnDark)
        }

        Section("其他資訊") {
            Picker("難度", selection: $difficulty) {
                ForEach(RecipeDifficulty.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("難度")
            HStack {
                Text("大約花費")
                TextField("例如 約 NT$120", text: $cost)
                    .multilineTextAlignment(.trailing)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("哪裡買")
                HStack(spacing: 8) {
                    ForEach(RecipeSource.allCases) { source in
                        HomeChip(title: source.title, isSelected: sources.contains(source)) {
                            if sources.contains(source) { sources.remove(source) } else { sources.insert(source) }
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            Toggle("含酒精", isOn: $containsAlcohol)
                .tint(HomeTheme.accentOnDark)
        }
    }

    private func removeButton(label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "minus.circle.fill")
                .foregroundStyle(disabled ? AppTheme.textSecondary : AppTheme.danger)
        }
        .buttonStyle(.borderless)
        .disabled(disabled)
        .accessibilityLabel(label)
    }

    private func post() {
        var recipe: ForumRecipe?
        if includesRecipe {
            let costText = trimmed(cost)
            recipe = ForumRecipe(
                ingredients: filledIngredients, steps: filledSteps, difficulty: difficulty,
                estimatedCost: costText.isEmpty ? "未填" : costText,
                sources: RecipeSource.allCases.filter { sources.contains($0) },
                containsAlcohol: containsAlcohol)
        }
        store.addPost(title: title, body: bodyText, category: category, tags: parsedTags, recipe: recipe)
        dismiss()
    }

    private var parsedTags: [String] {
        tagsText.split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == "，" })
            .map { $0.hasPrefix("#") ? String($0) : "#" + $0 }
            .filter { $0.count > 1 }
    }
}
