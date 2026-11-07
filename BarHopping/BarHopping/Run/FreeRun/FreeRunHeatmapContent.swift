import MapKit
import SwiftUI

struct FreeRunHeatmapContent: MapContent, Equatable {
    private let id = UUID()
    private let lines: [Line]

    private struct Line: Identifiable {
        let id: Int
        let polyline: MKPolyline
        let heat: Double
    }

    init(segments: [PopularRouteSegment]) {
        lines = segments.enumerated().map { index, segment in
            let coordinates = segment.path.map {
                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
            }
            return Line(id: index, polyline: MKPolyline(coordinates: coordinates, count: coordinates.count), heat: segment.heat)
        }
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    var body: some MapContent {
        ForEach(lines) { line in
            MapPolyline(line.polyline)
                .stroke(FreeRunHeatStyle.color(line.heat).opacity(0.35 + line.heat * 0.6),
                        style: StrokeStyle(lineWidth: 3 + line.heat * 3, lineCap: .round, lineJoin: .round))
        }
    }
}
