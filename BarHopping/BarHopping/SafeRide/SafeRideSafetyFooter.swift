import SwiftUI

struct SafeRideSafetyFooter: View {
    @Environment(\.openURL) private var openURL
    @State private var launcher = SafeRideLauncher()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("喝酒不開車、不騎車。等車時待在明亮安全的地方，跟朋友說一聲你的行程。")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("緊急狀況請撥 110／119")
                .font(.caption.weight(.semibold))
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { emergencyButtons }
                VStack(alignment: .leading, spacing: 6) { emergencyButtons }
            }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .tint(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .alert("確認撥打電話", isPresented: $launcher.showingPhoneConfirmation,
               presenting: launcher.pendingCall) { call in
            Button("撥打 \(call.number)") { launcher.confirmPhoneCall(using: openURL) }
            Button("取消", role: .cancel) { }
        } message: { call in
            Text("即將撥打\(call.name)（\(call.number)）。是否繼續？")
        }
        .alert("無法撥打電話", isPresented: $launcher.showingError) { } message: {
            Text(launcher.errorMessage)
        }
    }

    private var emergencyButtons: some View {
        Group {
            Button("110 報警", systemImage: "phone") {
                launcher.requestPhoneCall(name: "110 報警", number: "110")
            }
            Button("119 救護／消防", systemImage: "phone") {
                launcher.requestPhoneCall(name: "119 救護／消防", number: "119")
            }
        }
        .frame(minHeight: 44)
    }
}
