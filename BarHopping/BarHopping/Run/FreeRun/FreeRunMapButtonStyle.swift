import SwiftUI

struct FreeRunMapButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 46, height: 46)
            .foregroundStyle(isEnabled ? AppTheme.textPrimary : AppTheme.textTertiary)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(AppTheme.textTertiary.opacity(0.4)))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
