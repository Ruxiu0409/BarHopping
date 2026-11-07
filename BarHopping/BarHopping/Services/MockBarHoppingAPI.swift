import Foundation

// MARK: - MockBarHoppingAPI
//
// 依共用契約（docs/specs/00-product-and-contract.md 第 5–7 節）模擬 HTTP API v1。
// 酒吧與服務範圍讀取 App 內附的臺中市 OSM JSON。路線幾何為示範用的 L 形折線，
// 不是實際路由結果，warnings 會註明。
//
// 可觸發的錯誤情境（給 UI 測試用；先通過輸入驗證才會觸發）：
//   路線標題 plan.title 含 "#422" → 422 NO_WALKABLE_ROUTE，waypointIds = [第一個 stop 的 waypoint.id]
//   路線標題 plan.title 含 "#503" → 503 UPSTREAM_UNAVAILABLE（retryable）
//   路線標題 plan.title 含 "#504" → 延遲 2 秒後 504 UPSTREAM_TIMEOUT（retryable）
//   路線標題 plan.title 含 "#429" → 429 RATE_LIMITED（retryable，message 帶 Retry-After 秒數）
//   搜尋 q = "zzz"                → 自然的空結果（items 為空、nextCursor 為 nil）
//   起點／站點／終點放在台中市服務範圍外 → 422 OUTSIDE_SERVICE_AREA，waypointIds 為範圍外的點
//   九間酒吧、dwell 超出 0–180、重複 id 等 → 400 INVALID_REQUEST
// retryable 只有 RATE_LIMITED、UPSTREAM_UNAVAILABLE、UPSTREAM_TIMEOUT 為 true。

nonisolated struct MockBarHoppingAPI: BarHoppingAPI {
    static let maxStops = 8
    static let walkingSpeedMetersPerSecond = 1.25
    static let routeDelay: ClosedRange<Int> = 300...800      // 毫秒
    static let placesDelay: ClosedRange<Int> = 120...300     // 毫秒
    static let timeoutDelay: Duration = .seconds(2)
    static let rateLimitRetryAfterSeconds = 30

    static let estimateWarning = "路線依地圖資料估算，未確認即時封路與店家營業狀態"
    static let mockWarning = "此為示範資料，非實際路由結果"

    var places: [Place]
    var serviceArea: GeoJSONPolygon
    /// 關掉延遲可加快預覽或邏輯驗證。
    var simulatesLatency: Bool
    private var dataError: Error?
    private var placeDataUpdatedAt: Date = .distantPast

    init(places: [Place]? = nil,
         serviceArea: GeoJSONPolygon? = nil,
         simulatesLatency: Bool = true) {
        self.places = places ?? []
        self.serviceArea = serviceArea ?? GeoJSONPolygon(coordinates: [])
        self.simulatesLatency = simulatesLatency
        do {
            if places == nil { self.places = try MockFixtures.places.get() }
            if serviceArea == nil { self.serviceArea = try MockFixtures.serviceArea.get() }
            if let places {
                placeDataUpdatedAt = places.map(\.updatedAt).max() ?? .distantPast
            } else {
                placeDataUpdatedAt = try MockFixtures.metadata.get().placeDataUpdatedAt
            }
        } catch {
            dataError = error
        }
        self.places.sort { $0.id < $1.id }
    }

    // MARK: GET /v1/config

    func config() async throws -> AppConfig {
        try checkData()
        try await sleep(milliseconds: Self.placesDelay)
        return AppConfig(
            serviceArea: serviceArea,
            maxStops: Self.maxStops,
            mapStyleUrl: URL(string: "https://tiles.openfreemap.org/styles/dark")!,
            attributions: [
                Attribution(text: "© OpenStreetMap contributors", url: URL(string: "https://www.openstreetmap.org/copyright")!),
                Attribution(text: "OpenFreeMap", url: URL(string: "https://openfreemap.org")!),
            ],
            placeDataUpdatedAt: placeDataUpdatedAt)
    }

    // MARK: GET /v1/places

    func places(in bbox: BoundingBox, query: String?, limit: Int, cursor: String?) async throws -> PlacesPage {
        guard (1...100).contains(limit) else { throw Self.invalid("limit 必須介於 1 至 100") }
        guard Self.isValid(bbox) else { throw Self.invalid("bbox 格式不正確，需為 west,south,east,north") }
        var afterId: String?
        if let cursor {
            guard let id = Self.decodeCursor(cursor) else { throw Self.invalid("cursor 無效") }
            afterId = id
        }
        let q = query?.trimmingCharacters(in: .whitespacesAndNewlines)

        try checkData()
        try await sleep(milliseconds: Self.placesDelay)

        let matches = places.filter { place in
            guard bbox.contains(place.coordinate) else { return false }
            guard let q, !q.isEmpty else { return true }
            return place.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
        }
        // places 已依 id 排序；游標記錄上一頁最後一筆 id。
        let remaining = afterId.map { after in matches.filter { $0.id > after } } ?? matches
        let page = Array(remaining.prefix(limit))
        let next = remaining.count > limit ? page.last.map { Self.encodeCursor(afterId: $0.id) } : nil
        return PlacesPage(items: page, nextCursor: next)
    }

    // MARK: GET /v1/places/{id}

    func place(id: String) async throws -> Place {
        try checkData()
        try await sleep(milliseconds: Self.placesDelay)
        guard let place = places.first(where: { $0.id == id }) else {
            throw ServiceError(clientRequestId: nil, code: .placeNotFound,
                               message: "找不到這間店（可能已從地圖資料移除）", retryable: false, waypointIds: [])
        }
        return place
    }

    // MARK: POST /v1/routes/preview

    func previewRoute(_ request: RouteRequest) async throws -> RouteResult {
        try checkData()
        try validate(request)   // 輸入非法時不呼叫「路由引擎」，立即回應
        let plan = request.plan
        let rid = request.clientRequestId

        if plan.title.contains("#504") {
            try await sleepExactly(Self.timeoutDelay)
            throw ServiceError(clientRequestId: rid, code: .upstreamTimeout,
                               message: "路線服務回應逾時，請稍後再試", retryable: true, waypointIds: [])
        }
        try await sleep(milliseconds: Self.routeDelay)
        if plan.title.contains("#422"), let first = plan.stops.first {
            throw ServiceError(clientRequestId: rid, code: .noWalkableRoute,
                               message: "「\(first.waypoint.name)」附近找不到可步行的道路，請移動站點後再試",
                               retryable: false, waypointIds: [first.waypoint.id])
        }
        if plan.title.contains("#503") {
            throw ServiceError(clientRequestId: rid, code: .upstreamUnavailable,
                               message: "路線服務暫時無法使用，請稍後再試", retryable: true, waypointIds: [])
        }
        if plan.title.contains("#429") {
            throw ServiceError(clientRequestId: rid, code: .rateLimited,
                               message: "請求太頻繁，請在 \(Self.rateLimitRetryAfterSeconds) 秒後再試（Retry-After: \(Self.rateLimitRetryAfterSeconds)）",
                               retryable: true, waypointIds: [])
        }

        let points = plan.orderedWaypoints
        var legs: [RouteLeg] = []
        legs.reserveCapacity(points.count - 1)
        for (from, to) in zip(points, points.dropFirst()) {
            legs.append(Self.mockLeg(from: from, to: to))
        }
        let distance = legs.reduce(0) { $0 + $1.distanceMeters }
        let walking = legs.reduce(0) { $0 + $1.walkingDurationSeconds }
        let dwell = Double(plan.stops.reduce(0) { $0 + $1.dwellMinutes } * 60)
        return RouteResult(clientRequestId: rid, planId: plan.id, legs: legs,
                           distanceMeters: distance, walkingDurationSeconds: walking,
                           dwellDurationSeconds: dwell, totalDurationSeconds: walking + dwell,
                           warnings: [Self.estimateWarning, Self.mockWarning],
                           computedAt: .now, routingDataUpdatedAt: MockFixtures.routingDataUpdatedAt)
    }

    // MARK: - 驗證（規格第 6–7 節、Agent B 驗收案例）

    func validate(_ request: RouteRequest) throws {
        let rid = request.clientRequestId
        let plan = request.plan
        func invalid(_ message: String, _ ids: [String] = []) -> ServiceError {
            ServiceError(clientRequestId: rid, code: .invalidRequest, message: message, retryable: false, waypointIds: ids)
        }

        guard !rid.trimmingCharacters(in: .whitespaces).isEmpty else { throw invalid("缺少 clientRequestId") }
        guard plan.schemaVersion == 1 else { throw invalid("不支援的 schemaVersion：\(plan.schemaVersion)") }
        guard request.profile == .walking else { throw invalid("只支援步行路線") }
        guard let origin = plan.origin else { throw invalid("缺少起點") }
        guard (1...Self.maxStops).contains(plan.stops.count) else {
            throw invalid("每條路線需有 1 至 \(Self.maxStops) 間酒吧，目前為 \(plan.stops.count) 間")
        }
        switch plan.endMode {
        case .returnToOrigin:
            if let d = plan.destination { throw invalid("回到起點時不可指定終點", [d.id]) }
        case .custom:
            if plan.destination == nil { throw invalid("單程路線需指定終點") }
        }

        let all = [origin] + plan.stops.map(\.waypoint) + (plan.destination.map { [$0] } ?? [])

        let empty = all.filter { $0.id.isEmpty || $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !empty.isEmpty { throw invalid("站點缺少 id 或名稱", empty.map(\.id)) }

        let badCoords = all.filter { !$0.coordinate.isValid || !$0.coordinate.latitude.isFinite || !$0.coordinate.longitude.isFinite }
        if !badCoords.isEmpty { throw invalid("座標不合法", badCoords.map(\.id)) }

        var seenIds = Set<String>(), dupIds: [String] = []
        for w in all where !seenIds.insert(w.id).inserted { dupIds.append(w.id) }
        if !dupIds.isEmpty { throw invalid("站點 id 重複", Self.unique(dupIds)) }

        var seenPlaces = Set<String>(), dupPlaces: [String] = []
        for s in plan.stops {
            if let pid = s.waypoint.placeId, !seenPlaces.insert(pid).inserted { dupPlaces.append(s.waypoint.id) }
        }
        if !dupPlaces.isEmpty { throw invalid("同一間店不可加入兩次", dupPlaces) }

        let badDwell = plan.stops.filter { !Stop.dwellRange.contains($0.dwellMinutes) }
        if !badDwell.isEmpty { throw invalid("停留時間需為 0 至 180 分鐘", badDwell.map(\.waypoint.id)) }

        let outside = all.filter { !Self.contains(serviceArea, $0.coordinate) }
        if !outside.isEmpty {
            throw ServiceError(clientRequestId: rid, code: .outsideServiceArea,
                               message: "有站點在服務範圍（台中市）之外", retryable: false,
                               waypointIds: Self.unique(outside.map(\.id)))
        }
    }

    // MARK: - 示範幾何

    /// 先沿經度走、再沿緯度走的 L 形折線，每段插入中間點模擬街道。
    static func mockLeg(from: Waypoint, to: Waypoint) -> RouteLeg {
        let a = from.coordinate, b = to.coordinate
        var coords: [Coordinate]
        if a == b {
            coords = [a, a]
        } else {
            let corner = Coordinate(latitude: a.latitude, longitude: b.longitude)
            coords = [a]
            for t in [1.0 / 3, 2.0 / 3, 1] { coords.append(lerp(a, corner, t)) }
            for t in [1.0 / 3, 2.0 / 3, 1] { coords.append(lerp(corner, b, t)) }
            coords = coords.enumerated().filter { i, c in i == 0 || c != coords[i - 1] }.map(\.element)
            if coords.count < 2 { coords = [a, b] }
        }
        let distance = zip(coords, coords.dropFirst()).reduce(0) { $0 + haversine($1.0, $1.1) } * 1.0
        return RouteLeg(fromWaypointId: from.id, toWaypointId: to.id,
                        distanceMeters: distance, walkingDurationSeconds: distance / walkingSpeedMetersPerSecond,
                        geometry: GeoJSONLineString(coordinates: coords.map { [$0.longitude, $0.latitude] }),
                        snappedFrom: a, snappedTo: b)
    }

    private static func lerp(_ a: Coordinate, _ b: Coordinate, _ t: Double) -> Coordinate {
        t == 1 ? b : Coordinate(latitude: a.latitude + (b.latitude - a.latitude) * t,
                                longitude: a.longitude + (b.longitude - a.longitude) * t)
    }

    static func haversine(_ a: Coordinate, _ b: Coordinate) -> Double {
        let r = 6_371_000.0
        let dLat = (b.latitude - a.latitude) * .pi / 180
        let dLon = (b.longitude - a.longitude) * .pi / 180
        let h = sin(dLat / 2) * sin(dLat / 2)
            + cos(a.latitude * .pi / 180) * cos(b.latitude * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * r * asin(min(1, sqrt(h)))
    }

    /// Ray casting；只看外環。
    static func contains(_ polygon: GeoJSONPolygon, _ c: Coordinate) -> Bool {
        guard let ring = polygon.coordinates.first, ring.count >= 3 else { return false }
        var inside = false
        var j = ring.count - 1
        for i in ring.indices {
            let xi = ring[i][0], yi = ring[i][1], xj = ring[j][0], yj = ring[j][1]
            if (yi > c.latitude) != (yj > c.latitude),
               c.longitude < (xj - xi) * (c.latitude - yi) / (yj - yi) + xi {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    // MARK: - 工具

    private func checkData() throws {
        if let dataError { throw dataError }
    }

    private static func isValid(_ b: BoundingBox) -> Bool {
        [b.west, b.south, b.east, b.north].allSatisfy(\.isFinite)
            && (-180...180).contains(b.west) && (-180...180).contains(b.east)
            && (-90...90).contains(b.south) && (-90...90).contains(b.north)
            && b.west <= b.east && b.south <= b.north
    }

    static func encodeCursor(afterId: String) -> String {
        Data("v1:\(afterId)".utf8).base64EncodedString()
    }

    static func decodeCursor(_ cursor: String) -> String? {
        guard let data = Data(base64Encoded: cursor), let s = String(data: data, encoding: .utf8),
              s.hasPrefix("v1:") else { return nil }
        return String(s.dropFirst(3))
    }

    private static func invalid(_ message: String) -> ServiceError {
        ServiceError(clientRequestId: nil, code: .invalidRequest, message: message, retryable: false, waypointIds: [])
    }

    private static func unique(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    /// 隨機延遲；Task 被取消時丟出 CancellationError。
    private func sleep(milliseconds range: ClosedRange<Int>) async throws {
        guard simulatesLatency else { try Task.checkCancellation(); return }
        try await Task.sleep(for: .milliseconds(Int.random(in: range)))
    }

    private func sleepExactly(_ duration: Duration) async throws {
        guard simulatesLatency else { try Task.checkCancellation(); return }
        try await Task.sleep(for: duration)
    }
}
