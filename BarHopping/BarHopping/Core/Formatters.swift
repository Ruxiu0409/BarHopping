import Foundation

/// 顯示用換算。API 一律給公尺與秒，客戶端只做換算與四捨五入。
nonisolated enum Fmt {
    static func distance(_ meters: Double) -> String {
        meters < 1000 ? "\(Int(meters.rounded())) 公尺" : String(format: "%.1f 公里", meters / 1000)
    }

    static func duration(_ seconds: Double) -> String {
        let total = Int((seconds / 60).rounded())
        let h = total / 60, m = total % 60
        if h == 0 { return "\(m) 分鐘" }
        return m == 0 ? "\(h) 小時" : "\(h) 小時 \(m) 分鐘"
    }

    static func minutes(_ minutes: Int) -> String { duration(Double(minutes * 60)) }
}
