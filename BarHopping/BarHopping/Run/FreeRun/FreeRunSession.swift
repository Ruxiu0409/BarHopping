import Foundation

nonisolated enum FreeRunRules {
    static let arrivalMeters = 40.0
    static let departureMeters = 60.0
    static let maximumAccuracyMeters = 50.0

    static func distance(_ a: Coordinate, _ b: Coordinate) -> Double {
        let latitude = (b.latitude - a.latitude) * .pi / 180
        let longitude = (b.longitude - a.longitude) * .pi / 180
        let h = pow(sin(latitude / 2), 2)
            + cos(a.latitude * .pi / 180) * cos(b.latitude * .pi / 180) * pow(sin(longitude / 2), 2)
        return 6_371_000 * 2 * asin(sqrt(min(1, max(0, h))))
    }
}

nonisolated struct FreeRunSample: Sendable {
    let coordinate: Coordinate
    let accuracy: Double
    let timestamp: Date
}

nonisolated struct FreeRunVisit: Identifiable, Sendable {
    let id = UUID()
    let barID: String
    let name: String
    let timestamp: Date
    let coordinate: Coordinate
}

nonisolated struct FreeRunNearbyBar: Identifiable {
    let place: Place
    let distance: Double
    var id: String { place.id }
}

/// 不依賴定位框架或畫面；真實定位與示範位置都經過此狀態機。
nonisolated struct FreeRunSession {
    let startedAt: Date
    let isDemo: Bool
    private(set) var endedAt: Date?
    private(set) var samples: [FreeRunSample] = []
    private(set) var visits: [FreeRunVisit] = []
    private(set) var distanceMeters = 0.0
    private(set) var nearby: [FreeRunNearbyBar] = []
    private(set) var activeBarID: String?
    private(set) var hasArrived = false
    private(set) var pausedAt: Date?
    private var pausedSeconds: TimeInterval = 0
    private(set) var hasAccurateLocation = false
    private(set) var currentCoordinate: Coordinate?
    private(set) var trackSegments: [[Coordinate]] = []
    private var previous: FreeRunSample?

    var activeBar: FreeRunNearbyBar? { nearby.first { $0.id == activeBarID } }
    var uniqueBarCount: Int { Set(visits.map(\.barID)).count }

    var isPaused: Bool { pausedAt != nil }

    func elapsed(at date: Date) -> TimeInterval {
        let end = endedAt ?? date
        let currentPause = pausedAt.map { max(0, end.timeIntervalSince($0)) } ?? 0
        return max(0, end.timeIntervalSince(startedAt) - pausedSeconds - currentPause)
    }

    mutating func pause(at date: Date) {
        guard endedAt == nil, pausedAt == nil else { return }
        pausedAt = date
        previous = nil
        hasArrived = false
    }

    mutating func resume(at date: Date) {
        guard endedAt == nil, let pausedAt else { return }
        pausedSeconds += max(0, date.timeIntervalSince(pausedAt))
        self.pausedAt = nil
        previous = nil
        updateArrival()
    }

    func canRecord(_ id: String, at date: Date) -> Bool {
        !visits.contains { $0.barID == id }
    }

    mutating func breakTracking() {
        previous = nil
        hasArrived = false
        hasAccurateLocation = false
        currentCoordinate = nil
    }

    mutating func receive(_ sample: FreeRunSample, places: [Place], now: Date) {
        guard endedAt == nil else { return }
        guard sample.coordinate.isValid, sample.accuracy.isFinite,
              sample.accuracy >= 0, sample.accuracy <= FreeRunRules.maximumAccuracyMeters,
              abs(now.timeIntervalSince(sample.timestamp)) <= 15 else {
            breakTracking()
            return
        }
        if let last = samples.last, sample.timestamp <= last.timestamp { return }
        hasAccurateLocation = true
        currentCoordinate = sample.coordinate
        nearby = places.map { FreeRunNearbyBar(place: $0, distance: FreeRunRules.distance(sample.coordinate, $0.coordinate)) }
            .sorted { $0.distance == $1.distance ? $0.id < $1.id : $0.distance < $1.distance }
        if activeBarID == nil {
            activeBarID = NextBarRecommender.recommend(near: sample.coordinate, places: places,
                                                       excluding: Set(visits.map(\.barID)))?.id
        }
        if isPaused { hasArrived = false; return }
        if let previous {
            let distance = FreeRunRules.distance(previous.coordinate, sample.coordinate)
            let seconds = sample.timestamp.timeIntervalSince(previous.timestamp)
            // 忽略 GPS 漂移與不合理跳點，恢復前景後也不跨空白區間連接。
            if distance >= 3, seconds > 0, isDemo || distance / seconds <= 12 {
                distanceMeters += distance
                samples.append(sample)
                trackSegments[trackSegments.count - 1].append(sample.coordinate)
                self.previous = sample
            } else if !isDemo, distance / max(seconds, 0.001) > 12 {
                self.previous = sample
                trackSegments.append([sample.coordinate])
            }
        } else {
            samples.append(sample)
            trackSegments.append([sample.coordinate])
            previous = sample
        }
        updateArrival()
    }

    mutating func selectBar(_ id: String) {
        guard endedAt == nil, !isPaused, hasAccurateLocation, canRecord(id, at: .now), nearby.contains(where: { $0.id == id }) else { return }
        activeBarID = id
        hasArrived = false
        updateArrival()
    }

    @discardableResult
    mutating func record(at date: Date) -> FreeRunVisit? {
        guard endedAt == nil, !isPaused, hasAccurateLocation, hasArrived, let bar = activeBar,
              bar.distance <= FreeRunRules.departureMeters, canRecord(bar.id, at: date) else { return nil }
        let visit = FreeRunVisit(barID: bar.id, name: bar.place.name, timestamp: date, coordinate: bar.place.coordinate)
        visits.append(visit)
        activeBarID = nearby.first { canRecord($0.id, at: date) }?.id
        hasArrived = false
        updateArrival()
        return visit
    }

    private mutating func updateArrival() {
        guard hasAccurateLocation, let bar = activeBar else { hasArrived = false; return }
        hasArrived = bar.distance <= (hasArrived ? FreeRunRules.departureMeters : FreeRunRules.arrivalMeters)
    }

    mutating func finish(at date: Date) {
        guard endedAt == nil else { return }
        endedAt = date
        breakTracking()
    }
}
