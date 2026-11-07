import SwiftUI

struct LaunchAppIconView: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height) * 0.76

            Image("LaunchAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)
                .clipShape(RoundedRectangle(cornerRadius: side * 0.2237, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: side * 0.025, y: side * 0.02)
                .accessibilityLabel("BarHopping")
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
