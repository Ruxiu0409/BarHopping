import Foundation
import SwiftUI

struct JoinGroupSheet: View {
    let onJoined: (UUID) -> Void
    @Environment(GroupsStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("輸入邀請碼", text: $code)
                        .keyboardType(.asciiCapable)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .submitLabel(.go)
                        .onSubmit(join)
                        .onChange(of: code) { error = nil }
                        .accessibilityLabel("團體邀請碼")
                    if let error {
                        Label(error, systemImage: "exclamationmark.circle.fill")
                            .font(.subheadline).foregroundStyle(.red)
                            .accessibilityIdentifier("groups.invite.error")
                    }
                    Button("加入團體", action: join)
                        .disabled(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } header: { Text("和朋友一起走") } footer: {
                    Text("邀請碼不分大小寫。已加入的團體會直接開啟。")
                }
                Section("試試示意邀請碼") {
                    LabeledContent("私密・週末巷口散步隊", value: "LANE18")
                    LabeledContent("公開・逢甲下班小酌團", value: "FENG66")
                    Text("這些碼僅供本機體驗，不會連線或通知其他人。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("用邀請碼加入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
            }
        }
        .tint(AppTheme.accentOnDark)
    }

    private func join() {
        guard let id = store.join(inviteCode: code) else {
            error = "找不到這組邀請碼，請確認後再試一次。"
            return
        }
        dismiss()
        onJoined(id)
    }
}
