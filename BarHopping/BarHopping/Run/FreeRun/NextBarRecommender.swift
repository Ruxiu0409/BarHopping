import Foundation

nonisolated enum NextBarRecommender {
    static func recommend(near coordinate: Coordinate, places: [Place], excluding visited: Set<String>) -> Place? {
        places.filter { !visited.contains($0.id) }.min {
            let left = FreeRunRules.distance(coordinate, $0.coordinate)
            let right = FreeRunRules.distance(coordinate, $1.coordinate)
            return left == right ? $0.id < $1.id : left < right
        }
    }

    static func walkingMinutes(for meters: Double) -> Int {
        max(1, Int(ceil(meters / 75)))
    }
}
