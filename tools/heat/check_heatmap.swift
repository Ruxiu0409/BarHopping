import Foundation

// 編譯方式見 tools/heat/check_heatmap.py；直接連結 App 的模型與熱力圖實作。
@main
struct CheckHeatmap {
    static func main() throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let decodeStart = ContinuousClock.now
        let routes = try JSONDecoder().decode([PopularRoute].self, from: data)
        let decodeTime = decodeStart.duration(to: .now)
        precondition(routes.count == 144)
        precondition(Set(routes.map(\.id)).count == routes.count)
        precondition(routes.allSatisfy {
            (1_000...5_000).contains($0.distanceMeters)
                && (5...250).contains($0.runCount)
                && $0.path.count >= 2 && $0.path.allSatisfy(\.isValid)
        })
        let start = ContinuousClock.now
        let features = PopularRouteHeatmap.segments(from: routes)
        let elapsed = start.duration(to: .now)
        precondition(!features.isEmpty)
        precondition(features.allSatisfy { $0.path.count >= 2 && $0.runCount > 0 && (0...1).contains($0.heat) })
        let coveredRuns = features.map(\.runCount).reduce(0, +)
        let result: [String: Any] = [
            "routes": routes.count,
            "bytes": data.count,
            "inputSegments": routes.map { $0.path.count - 1 }.reduce(0, +),
            "uniqueEdges": features.map { $0.path.count - 1 }.reduce(0, +),
            "mergedFeatures": features.count,
            "sumFeatureRunCounts": coveredRuns,
            "maximumSharedRunCount": features.map(\.runCount).max()!,
            "decodeMilliseconds": milliseconds(decodeTime),
            "heatmapMilliseconds": milliseconds(elapsed),
            "scope": "one macOS host run; App Core implementation; excludes MapLibre rendering and iPhone timing"
        ]
        print(String(decoding: try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]), as: UTF8.self))
    }

    static func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1_000 + Double(duration.components.attoseconds) / 1e15
    }
}
