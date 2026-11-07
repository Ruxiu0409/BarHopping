import SwiftUI

struct FreeRunMapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(width: 46, height: 46)
            .foregroundStyle(.white)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.16)))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
