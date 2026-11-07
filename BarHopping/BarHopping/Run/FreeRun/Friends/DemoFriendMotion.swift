import Foundation

/// 以時間與座標決定模擬位置，可用固定時間重現，不依賴地圖或定位框架。
nonisolated struct DemoFriendMotion {
    private var coordinates: [Coordinate] = []
    private var previousDate: Date?

    mutating func locations(around anchor: Coordinate, bars: [Coordinate], at date: Date) -> [FriendLocation] {
        let elapsed = max(0, min(3, date.timeIntervalSince(previousDate ?? date)))
        previousDate = date
        let names = ["紫薯", "氣泡", "夜貓"]
        let symbols = ["moon.fill", "sparkles", "cat.fill"]
        if coordinates.isEmpty {
            coordinates = (0..<3).map { index in
                Self.offset(anchor, north: Double(index - 1) * 35, east: Double(index + 1) * 25)
            }
        }
        let seconds = date.timeIntervalSinceReferenceDate
        return (0..<3).map { index in
            let phase = seconds / 35 + Double(index) * 2.1
            let nearbyBar = bars.filter { FreeRunRules.distance(anchor, $0) < 250 }
                .min { FreeRunRules.distance(coordinates[index], $0) < FreeRunRules.distance(coordinates[index], $1) }
            // 每分鐘的前段靠近酒吧，目標固定時會停留，其他時間在使用者附近散步。
            let resting = Int(seconds / 20 + Double(index)) % 3 == 0
            let target = resting ? (nearbyBar ?? anchor)
                : Self.offset(anchor, north: sin(phase) * 65, east: cos(phase) * 75)
            let distance = FreeRunRules.distance(coordinates[index], target)
            let fraction = distance > 0 ? min(1, elapsed * 1.4 / distance) : 0
            coordinates[index] = Coordinate(
                latitude: coordinates[index].latitude + (target.latitude - coordinates[index].latitude) * fraction,
                longitude: coordinates[index].longitude + (target.longitude - coordinates[index].longitude) * fraction
            )
            return FriendLocation(id: index, nickname: names[index], symbol: symbols[index],
                                  coordinate: coordinates[index], updatedAt: date)
        }
    }

    private static func offset(_ center: Coordinate, north: Double, east: Double) -> Coordinate {
        Coordinate(latitude: center.latitude + north / 111_195,
                   longitude: center.longitude + east / (111_195 * max(0.01, cos(center.latitude * .pi / 180))))
    }
}
