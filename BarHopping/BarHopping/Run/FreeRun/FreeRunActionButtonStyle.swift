import SwiftUI

struct FreeRunActionButtonStyle: ButtonStyle {
    var prominent = false
    @Environment(\.isEnabled) private var isEnabled

    static let cornerRadius: CGFloat = 12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(prominent ? .headline : .subheadline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(!isEnabled ? AppTheme.textTertiary :
                configuration.role == .destructive ? AppTheme.danger :
                prominent ? .white : AppTheme.textPrimary)
            .background(prominent && isEnabled ? AppTheme.accent : AppTheme.elevated,
                        in: RoundedRectangle(cornerRadius: Self.cornerRadius))
            .overlay {
                if !prominent {
                    RoundedRectangle(cornerRadius: Self.cornerRadius)
                        .strokeBorder(AppTheme.textTertiary.opacity(0.3))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
