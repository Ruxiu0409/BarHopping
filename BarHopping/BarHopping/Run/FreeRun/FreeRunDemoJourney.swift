import Foundation

/// 示範位置只沿直線移動至下一站，抵達後等待；不是實際道路導航。
nonisolated struct FreeRunDemoJourney {
    private(set) var coordinate: Coordinate

    mutating func advance(toward target: Coordinate?, meters: Double, isPaused: Bool) -> Coordinate {
        guard !isPaused, let target, FreeRunRules.distance(coordinate, target) > 8 else { return coordinate }
        var path = FreeRunDemoPath(points: [coordinate, target])
        coordinate = path.advance(meters: meters) ?? coordinate
        return coordinate
    }
}
