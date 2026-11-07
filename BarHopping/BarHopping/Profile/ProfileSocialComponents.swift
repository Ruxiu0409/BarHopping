import SwiftUI
import UIKit

enum ProfilePhotoLoadError: Error {
    case unavailable
}

enum ProfileConnectionKind: String, Identifiable {
    case followers
    case following

    var id: String { rawValue }
    var title: String { self == .followers ? "粉絲" : "追蹤中" }
}

struct ProfileSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(AppTheme.elevated.opacity(configuration.isPressed ? 0.65 : 1), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(AppTheme.separator))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct ProfileAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(AppTheme.background)
            .padding(.horizontal, 12)
            .frame(minHeight: 42)
            .background(AppTheme.accent.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct ProfileEditorSheet: View {
    @Environment(UserProfileStore.self) private var userProfile
    @Environment(\.dismiss) private var dismiss
    @State private var nickname = ""
    @State private var bio = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    editorField(title: "顯示名稱", hint: "讓朋友知道怎麼稱呼你") {
                        TextField("你的名字", text: $nickname)
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                    }

                    editorField(title: "個人介紹", hint: "分享你的夜生活偏好") {
                        TextEditor(text: $bio)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 110)
                            .padding(10)
                            .background(AppTheme.elevated, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .bottomTrailing) {
                                Text("\(bio.count)/120")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(AppTheme.textTertiary)
                                    .padding(10)
                            }
                            .onChange(of: bio) { _, value in
                                if value.count > 120 { bio = String(value.prefix(120)) }
                            }
                    }

                    Label("你的資料只會保存在這部裝置上。", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .padding(20)
            }
            .background(AppTheme.background)
            .navigationTitle("編輯個人檔案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        userProfile.updateProfile(nickname: nickname, bio: bio)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                nickname = userProfile.nickname
                bio = userProfile.profileBio
            }
        }
        .preferredColorScheme(.dark)
        .presentationBackground(AppTheme.background)
        .presentationDetents([.medium, .large])
    }

    private func editorField<Content: View>(title: String, hint: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.headline)
            content()
            Text(hint)
                .font(.caption)
                .foregroundStyle(AppTheme.textTertiary)
        }
    }
}

struct ProfileConnectionsSheet: View {
    @Environment(UserProfileStore.self) private var userProfile
    @Environment(\.dismiss) private var dismiss
    let kind: ProfileConnectionKind
    @State private var followedIDs: Set<String> = ["yiwen", "jason"]

    private let members: [(id: String, name: String, handle: String, initials: String, color: Color)] = [
        ("yiwen", "林以文", "@yiwen.nights", "以", .purple),
        ("jason", "Jason Chen", "@jason.walks", "J", .blue),
        ("mika", "Mika 黃", "@mika.afterhours", "M", .pink),
        ("cheng", "陳小酒", "@cheng.taiwan", "酒", .teal),
        ("vicky", "Vicky Lin", "@vicky.citylights", "V", .orange),
        ("leo", "Leo 夜行", "@leo.onfoot", "L", .green),
    ]

    var body: some View {
        NavigationStack {
            List(members, id: \.id) { member in
                HStack(spacing: 12) {
                    Text(member.initials)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(member.color.gradient, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(member.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(member.handle)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    Button {
                        if followedIDs.contains(member.id) {
                            followedIDs.remove(member.id)
                            userProfile.followingCount = max(0, userProfile.followingCount - 1)
                        } else {
                            followedIDs.insert(member.id)
                            userProfile.followingCount += 1
                        }
                    } label: {
                        Text(followedIDs.contains(member.id) ? "追蹤中" : "追蹤")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(followedIDs.contains(member.id) ? AppTheme.textPrimary : AppTheme.background)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(followedIDs.contains(member.id) ? AppTheme.elevated : AppTheme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.separator)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.background, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .safeAreaInset(edge: .top) {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.accent)
                    Text("在台中夜裡，一起走得更遠。")
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }
                .font(.caption)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(AppTheme.background)
            }
        }
        .preferredColorScheme(.dark)
        .presentationBackground(AppTheme.background)
        .presentationDetents([.medium, .large])
    }

}

struct CameraCaptureView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                onImageCaptured(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
