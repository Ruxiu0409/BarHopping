import Foundation

// 共用資料定義 v1（docs/specs/00-product-and-contract.md 第 5 節）。
// 不得引用任何地圖 SDK 型別。距離為公尺、時間為秒、日期為 ISO 8601 UTC。

nonisolated struct Coordinate: Codable, Hashable, Sendable {
    var latitude: Double
    var longitude: Double

    var isValid: Bool { (-90...90).contains(latitude) && (-180...180).contains(longitude) }
}

nonisolated enum PlaceCategory: String, Codable, Sendable {
    case bar, pub
}

nonisolated struct Place: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var coordinate: Coordinate
    var category: PlaceCategory
    var address: String?
    var openingHoursText: String?
    var source: String          // "osm"
    var sourceId: String        // 例如 "node/123456"
    var updatedAt: Date
}

nonisolated struct Waypoint: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var coordinate: Coordinate
    var placeId: String?        // 自訂站點為 nil

    static func custom(name: String, at coordinate: Coordinate) -> Waypoint {
        Waypoint(id: UUID().uuidString, name: name, coordinate: coordinate, placeId: nil)
    }

    static func from(_ place: Place) -> Waypoint {
        Waypoint(id: UUID().uuidString, name: place.name, coordinate: place.coordinate, placeId: place.id)
    }
}

nonisolated struct Stop: Codable, Hashable, Identifiable, Sendable {
    var waypoint: Waypoint
    var dwellMinutes: Int       // 0...180，預設 30

    var id: String { waypoint.id }
    static let defaultDwellMinutes = 30
    static let dwellRange = 0...180
}

nonisolated enum EndMode: String, Codable, Sendable {
    case returnToOrigin, custom
}

nonisolated struct RoutePlan: Codable, Hashable, Identifiable, Sendable {
    var schemaVersion: Int = 1
    var id: String
    var title: String
    var origin: Waypoint?
    var stops: [Stop]
    var endMode: EndMode
    var destination: Waypoint?  // endMode == .returnToOrigin 時必須為 nil
    var updatedAt: Date

    static let maxStops = 8

    static func empty() -> RoutePlan {
        RoutePlan(id: UUID().uuidString, title: "未命名路線", origin: nil, stops: [],
                  endMode: .returnToOrigin, destination: nil, updatedAt: .now)
    }

    /// 計算路線前缺少的項目；空陣列代表可以計算。
    var missingRequirements: [String] {
        var m: [String] = []
        if origin == nil { m.append("起點") }
        if stops.isEmpty { m.append("至少一間酒吧") }
        if endMode == .custom && destination == nil { m.append("終點") }
        return m
    }

    /// 依路由順序排列的所有點：origin, stops..., destination 或 origin。
    var orderedWaypoints: [Waypoint] {
        guard let origin else { return [] }
        let end = endMode == .returnToOrigin ? origin : destination
        return [origin] + stops.map(\.waypoint) + (end.map { [$0] } ?? [])
    }
}

nonisolated enum RouteProfile: String, Codable, Sendable { case walking }

nonisolated struct RouteRequest: Codable, Sendable {
    var clientRequestId: String
    var plan: RoutePlan
    var profile: RouteProfile = .walking
}

/// GeoJSON LineString，coordinates 為 [longitude, latitude]。
nonisolated struct GeoJSONLineString: Codable, Hashable, Sendable {
    var type: String = "LineString"
    var coordinates: [[Double]]

    var points: [Coordinate] {
        coordinates.compactMap { $0.count >= 2 ? Coordinate(latitude: $0[1], longitude: $0[0]) : nil }
    }
}

nonisolated struct RouteLeg: Codable, Hashable, Sendable {
    var fromWaypointId: String
    var toWaypointId: String
    var distanceMeters: Double
    var walkingDurationSeconds: Double
    var geometry: GeoJSONLineString
    var snappedFrom: Coordinate
    var snappedTo: Coordinate
}

nonisolated struct RouteResult: Codable, Hashable, Sendable {
    var clientRequestId: String
    var planId: String
    var legs: [RouteLeg]
    var distanceMeters: Double
    var walkingDurationSeconds: Double
    var dwellDurationSeconds: Double
    var totalDurationSeconds: Double
    var warnings: [String]
    var computedAt: Date
    var routingDataUpdatedAt: Date
}

nonisolated enum ServiceErrorCode: String, Codable, Sendable {
    case invalidRequest = "INVALID_REQUEST"
    case outsideServiceArea = "OUTSIDE_SERVICE_AREA"
    case noWalkableRoute = "NO_WALKABLE_ROUTE"
    case placeNotFound = "PLACE_NOT_FOUND"
    case rateLimited = "RATE_LIMITED"
    case upstreamUnavailable = "UPSTREAM_UNAVAILABLE"
    case upstreamTimeout = "UPSTREAM_TIMEOUT"
    /// 客戶端自用：網路中斷、解碼失敗等非服務端回傳的錯誤。
    case clientNetwork = "CLIENT_NETWORK"
}

nonisolated struct ServiceError: Codable, Error, Hashable, Sendable {
    var clientRequestId: String?
    var code: ServiceErrorCode
    var message: String
    var retryable: Bool
    var waypointIds: [String]
}

nonisolated struct Attribution: Codable, Hashable, Sendable {
    var text: String
    var url: URL
}

/// GET /v1/config
nonisolated struct AppConfig: Codable, Hashable, Sendable {
    var serviceArea: GeoJSONPolygon
    var maxStops: Int
    var mapStyleUrl: URL
    var attributions: [Attribution]
    var placeDataUpdatedAt: Date
}

nonisolated struct GeoJSONPolygon: Codable, Hashable, Sendable {
    var type: String = "Polygon"
    var coordinates: [[[Double]]]
}

/// bbox=west,south,east,north
nonisolated struct BoundingBox: Hashable, Sendable {
    var west: Double, south: Double, east: Double, north: Double

    func contains(_ c: Coordinate) -> Bool {
        (south...north).contains(c.latitude) && (west...east).contains(c.longitude)
    }
    var queryValue: String { "\(west),\(south),\(east),\(north)" }
}

/// GET /v1/places 回應
nonisolated struct PlacesPage: Codable, Hashable, Sendable {
    var items: [Place]
    var nextCursor: String?
}
