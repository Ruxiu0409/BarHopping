import SwiftUI

struct SafeRideButton: View {
    @State private var showingSafeRide = false

    var body: some View {
        Button("安全回家", systemImage: "car.side.fill") {
            showingSafeRide = true
        }
        .font(.headline)
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(AppTheme.accent)
        .controlSize(.large)
        .accessibilityHint("開啟代駕、計程車與示範叫車選單")
        .sheet(isPresented: $showingSafeRide) {
            SafeRideSheet()
        }
    }
}

#Preview {
    SafeRideButton()
        .padding()
        .preferredColorScheme(.dark)
}
