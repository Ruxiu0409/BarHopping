import SwiftUI

enum FreeRunHeatStyle {
    /// 與地圖分頁相同的五個色階，僅在 Run 內轉成 MapKit 色彩。
    static func color(_ heat: Double) -> Color {
        let stops: [(Double, Double, Double, Double)] = [
            (0, 0.12, 0.10, 0.32), (0.3, 0.40, 0.10, 0.50),
            (0.6, 0.90, 0.12, 0.56), (0.85, 1, 0.48, 0.75), (1, 1, 0.92, 0.97)
        ]
        let value = min(1, max(0, heat))
        for (a, b) in zip(stops, stops.dropFirst()) where value <= b.0 {
            let fraction = (value - a.0) / (b.0 - a.0)
            return Color(red: a.1 + (b.1 - a.1) * fraction,
                         green: a.2 + (b.2 - a.2) * fraction,
                         blue: a.3 + (b.3 - a.3) * fraction)
        }
        return AppTheme.accentOnDark
    }
}
