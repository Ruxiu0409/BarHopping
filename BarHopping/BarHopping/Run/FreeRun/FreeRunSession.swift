import Foundation

nonisolated enum FreeRunRules {
    static let arrivalMeters = 40.0
    static let departureMeters = 60.0
    static let maximumAccuracyMeters = 50.0
    static let repeatInterval: TimeInterval = 10 * 60
    static let demoMetersPerSecond = 3.5

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
    private(set) var hasAccurateLocation = false
    private var previous: FreeRunSample?

    var activeBar: FreeRunNearbyBar? { nearby.first { $0.id == activeBarID } }
    var uniqueBarCount: Int { Set(visits.map(\.barID)).count }

    func elapsed(at date: Date) -> TimeInterval { max(0, (endedAt ?? date).timeIntervalSince(startedAt)) }

    func canRecord(_ id: String, at date: Date) -> Bool {
        !visits.contains { $0.barID == id && date.timeIntervalSince($0.timestamp) < FreeRunRules.repeatInterval }
    }

    mutating func breakTracking() {
        previous = nil
        activeBarID = nil
        hasAccurateLocation = false
        nearby = []
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
        nearby = places.map { FreeRunNearbyBar(place: $0, distance: FreeRunRules.distance(sample.coordinate, $0.coordinate)) }
            .sorted { $0.distance == $1.distance ? $0.id < $1.id : $0.distance < $1.distance }
        if let previous {
            let distance = FreeRunRules.distance(previous.coordinate, sample.coordinate)
            let seconds = sample.timestamp.timeIntervalSince(previous.timestamp)
            // 忽略 GPS 漂移與不合理跳點，恢復前景後也不跨空白區間連接。
            if distance >= 3, seconds > 0, distance / seconds <= (isDemo ? 20 : 12) {
                distanceMeters += distance
                samples.append(sample)
                self.previous = sample
            } else if distance / max(seconds, 0.001) > (isDemo ? 20 : 12) {
                self.previous = sample
            }
        } else {
            samples.append(sample)
            previous = sample
        }
        if let current = activeBar, current.distance <= FreeRunRules.departureMeters {
            if !canRecord(current.id, at: now),
               let next = nearby.first(where: { $0.distance <= FreeRunRules.arrivalMeters && canRecord($0.id, at: now) }) {
                activeBarID = next.id
            }
        } else {
            activeBarID = nearby.first { $0.distance <= FreeRunRules.arrivalMeters }?.id
        }
    }

    mutating func selectBar(_ id: String) {
        guard hasAccurateLocation, nearby.contains(where: { $0.id == id && $0.distance <= FreeRunRules.arrivalMeters }) else { return }
        activeBarID = id
    }

    @discardableResult
    mutating func record(at date: Date) -> FreeRunVisit? {
        guard endedAt == nil, hasAccurateLocation, let bar = activeBar,
              bar.distance <= FreeRunRules.departureMeters, canRecord(bar.id, at: date) else { return nil }
        let visit = FreeRunVisit(barID: bar.id, name: bar.place.name, timestamp: date, coordinate: bar.place.coordinate)
        visits.append(visit)
        return visit
    }

    mutating func finish(at date: Date) {
        guard endedAt == nil else { return }
        endedAt = date
        breakTracking()
    }
}
