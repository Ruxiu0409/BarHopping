import Foundation

nonisolated enum FreeRunHeatmapCache {
    // One shared task also coalesces simultaneous sessions, without blocking the main actor.
    static let segments = Task.detached(priority: .utility) {
        let routes: [PopularRoute] = try BundledJSON.load("taichung-demo-popular-routes")
        return displaySegments(from: routes)
    }

    static func displaySegments(from routes: [PopularRoute]) -> [PopularRouteSegment] {
        let segments = PopularRouteHeatmap.segments(from: routes)
        return segments.enumerated().sorted {
            if $0.element.runCount != $1.element.runCount { return $0.element.runCount > $1.element.runCount }
            return $0.offset < $1.offset
        }.prefix(160).map(\.element)
    }
}
