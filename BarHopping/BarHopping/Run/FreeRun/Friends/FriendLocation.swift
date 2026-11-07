import Foundation

nonisolated struct FriendLocation: Identifiable, Equatable, Sendable {
    let id: Int
    let nickname: String
    let symbol: String
    let coordinate: Coordinate
    let updatedAt: Date

    func distance(from coordinate: Coordinate) -> Double {
        FreeRunRules.distance(coordinate, self.coordinate)
    }

    func age(at date: Date) -> Int {
        Int(max(0, date.timeIntervalSince(updatedAt)))
    }
}

/// 位置只在記憶體內使用。正式供應器需先取得雙方分享同意，再提供更新。
@MainActor
protocol FriendLocationProviding: AnyObject {
    func start(onLocations: @escaping ([FriendLocation]) -> Void)
    func updateAnchor(_ coordinate: Coordinate, bars: [Coordinate])
    func stop()
}
