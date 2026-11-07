import Foundation

/// 約一公尺格點的無向路網；同一路線重走不重複計入人數。
nonisolated enum PopularRouteHeatmap {
    private struct Node: Hashable, Comparable {
        var latitude: Int
        var longitude: Int

        init(_ coordinate: Coordinate) {
            latitude = Int((coordinate.latitude * 100_000).rounded())
            longitude = Int((coordinate.longitude * 100_000).rounded())
        }

        var coordinate: Coordinate {
            Coordinate(latitude: Double(latitude) / 100_000, longitude: Double(longitude) / 100_000)
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.latitude == rhs.latitude ? lhs.longitude < rhs.longitude : lhs.latitude < rhs.latitude
        }
    }

    private struct Edge: Hashable, Comparable {
        var a: Node
        var b: Node

        init(_ a: Node, _ b: Node) {
            self.a = min(a, b)
            self.b = max(a, b)
        }

        func other(_ node: Node) -> Node { node == a ? b : a }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.a == rhs.a ? lhs.b < rhs.b : lhs.a < rhs.a
        }
    }

    static func segments(from routes: [PopularRoute]) -> [PopularRouteSegment] {
        var counts: [Edge: Int] = [:]
        for route in routes where route.runCount > 0 {
            let nodes = route.path.filter(\.isValid).map(Node.init)
            var visited: Set<Edge> = []
            for (a, b) in zip(nodes, nodes.dropFirst()) where a != b {
                visited.insert(Edge(a, b))
            }
            for edge in visited { counts[edge, default: 0] += route.runCount }
        }
        guard let maximum = counts.values.max(), maximum > 0 else { return [] }
        var adjacency: [Node: [Edge]] = [:]
        for edge in counts.keys.sorted() {
            adjacency[edge.a, default: []].append(edge)
            adjacency[edge.b, default: []].append(edge)
        }
        var remaining = Set(counts.keys)
        var result: [PopularRouteSegment] = []
        for edge in counts.keys.sorted() {
            guard remaining.remove(edge) != nil, let count = counts[edge] else { continue }
            var path = [edge.a, edge.b]
            // 只穿過度數為二、兩邊人數相同的節點，保留分岔與熱度邊界。
            func extend(from start: Node) -> [Node] {
                var node = start
                var extensionNodes: [Node] = []
                while let neighbors = adjacency[node], neighbors.count == 2,
                      let next = neighbors.first(where: { remaining.contains($0) && counts[$0] == count }) {
                    remaining.remove(next)
                    node = next.other(node)
                    extensionNodes.append(node)
                }
                return extensionNodes
            }
            let tail = extend(from: edge.b)
            let head = extend(from: edge.a)
            path = Array(head.reversed()) + path + tail
            result.append(PopularRouteSegment(path: path.map(\.coordinate), runCount: count,
                                              heat: Double(count) / Double(maximum)))
        }
        return result
    }
}
