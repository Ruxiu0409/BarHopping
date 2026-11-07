import Foundation

/// 依公尺插值而非按陣列索引跳點，短路徑終點停留，不瞬移回起點。
nonisolated struct FreeRunDemoPath {
    let points: [Coordinate]
    private(set) var segment = 0
    private(set) var offset = 0.0

    var isFinished: Bool { segment >= points.count - 1 }

    mutating func advance(meters: Double) -> Coordinate? {
        guard let last = points.last else { return nil }
        var remaining = max(0, meters)
        while segment < points.count - 1 {
            let a = points[segment], b = points[segment + 1]
            let length = FreeRunRules.distance(a, b)
            if length <= offset + remaining {
                remaining -= max(0, length - offset)
                segment += 1
                offset = 0
            } else {
                offset += remaining
                let fraction = offset / length
                return Coordinate(latitude: a.latitude + (b.latitude - a.latitude) * fraction,
                                  longitude: a.longitude + (b.longitude - a.longitude) * fraction)
            }
        }
        return last
    }
}
