import SwiftUI

struct DrinkPassKeyVisual: View {
    var isDecorative = true

    var body: some View {
        Image(DrinkPassArtwork.keyVisualImageName)
            .resizable()
            .aspectRatio(1200.0 / 630.0, contentMode: .fit)
            .opacity(0.85)
            .background(AppTheme.background)
            .accessibilityLabel("龍蛇酒雜 LONG SER 9 ZA 主視覺")
            .accessibilityHidden(isDecorative)
    }
}
