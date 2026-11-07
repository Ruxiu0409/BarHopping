import Foundation

/// 示範位置只沿直線移動至下一站，抵達後等待；不是實際道路導航。
nonisolated struct FreeRunDemoJourney {
    private(set) var coordinate: Coordinate
    private var destination: Coordinate?
    private var origin: Coordinate?
    private var elapsed = 0.0

    init(coordinate: Coordinate) { self.coordinate = coordinate }

    mutating func advance(toward target: Coordinate?, seconds: Double, completedVisits: Int,
                          isPaused: Bool, waitsForFeedback: Bool = false) -> Coordinate {
        guard !isPaused, !waitsForFeedback, let target else { return coordinate }
        if destination != target {
            destination = target
            origin = coordinate
            elapsed = 0
        }
        guard let origin else { return coordinate }
        elapsed += max(0, seconds)
        let duration = completedVisits == 0 ? FreeRunDemoScript.firstLegSeconds : FreeRunDemoScript.nextLegSeconds
        let distance = FreeRunRules.distance(origin, target)
        let travelFraction = distance > 0 ? max(0, distance - FreeRunDemoScript.arrivalDistanceMeters) / distance : 0
        let fraction = min(1, elapsed / duration) * travelFraction
        coordinate = Coordinate(latitude: origin.latitude + (target.latitude - origin.latitude) * fraction,
                                longitude: origin.longitude + (target.longitude - origin.longitude) * fraction)
        return coordinate
    }
}
