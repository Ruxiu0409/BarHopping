import Foundation

nonisolated enum FreeRunDemoScript {
    static let firstLegSeconds = 3.0
    static let nextLegSeconds = 5.0
    static let scanSeconds = 3.0
    static let successSeconds = 1.0
    static let confettiSeconds = 1.8
    static let sampleSeconds = 0.25
    static let feedbackSampleSeconds = 0.1
    static let minimumStartDistanceMeters = 80.0
    static let arrivalDistanceMeters = FreeRunRules.arrivalMeters - 1

    static func startCoordinate(on path: [Coordinate], places: [Place]) -> Coordinate? {
        path.first { coordinate in
            guard let bar = NextBarRecommender.recommend(near: coordinate, places: places, excluding: []) else { return false }
            return FreeRunRules.distance(coordinate, bar.coordinate) >= minimumStartDistanceMeters
        } ?? path.first
    }
}
