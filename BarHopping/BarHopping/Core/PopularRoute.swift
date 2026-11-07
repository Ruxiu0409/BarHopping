import Foundation

nonisolated struct PopularRoute: Codable, Sendable, Identifiable {
    var id: String
    var title: String
    var runCount: Int
    var distanceMeters: Double
    var stopPlaceIds: [String]
    var stopNames: [String]
    var path: [Coordinate]
}

nonisolated struct PopularRouteSegment: Equatable, Sendable {
    var path: [Coordinate]
    var runCount: Int
    var heat: Double
}

nonisolated protocol PopularRouteProviding: Sendable {
    func routes() async throws -> [PopularRoute]
}
