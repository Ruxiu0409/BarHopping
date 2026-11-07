import SwiftUI

struct DrinkPassSafetyNotice: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("禁止酒駕")
            Text("飲酒過量，有害健康")
            Text("未滿 18 歲禁止飲酒")
        }
        .font(.subheadline.bold())
        .foregroundStyle(AppTheme.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }
}
