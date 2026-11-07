import SwiftUI

struct FreeRunHeadingCone: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: min(rect.width, rect.height) / 2,
                    startAngle: .degrees(-120), endAngle: .degrees(-60), clockwise: false)
        path.closeSubpath()
        return path
    }
}
