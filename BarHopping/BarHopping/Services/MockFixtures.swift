import Foundation

/// Mock 路由使用真實 OSM 目錄與臺中市行政邊界，幾何仍為示範路線。
nonisolated enum MockFixtures {
    static let routingDataUpdatedAt = JSONCoding.parseISO8601("2026-10-01T00:00:00Z") ?? .distantPast

    /// 地圖初始視角建議的中心（台中市西區／勤美一帶）。
    static let cityCenter = Coordinate(latitude: 24.1500, longitude: 120.6620)

    static let places: Result<[Place], Error> = Result { try BundledJSON.load("taichung-bars") }
    static let serviceArea: Result<GeoJSONPolygon, Error> = Result { try BundledJSON.load("taichung-service-area") }
    static let metadata: Result<BundledPlaceMetadata, Error> = Result { try BundledJSON.load("taichung-data-metadata") }
}
