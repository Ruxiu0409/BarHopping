import Foundation
import Observation

@MainActor @Observable
final class FreeRunStore {
    private(set) var session: FreeRunSession
    private(set) var status: FreeRunLocationStatus = .waiting
    private(set) var dataError: String?
    private(set) var now = Date.now
    private(set) var lastRecordedName: String?
    private(set) var feedbackCount = 0
    private(set) var friends: [FriendLocation] = []
    private(set) var heading: Double?
    private(set) var heatSegments: [PopularRouteSegment] = []
    private(set) var heatmapError: String?
    private(set) var mapAttributions: [String] = []
    var accelerated = false {
        didSet { (source as? FreeRunDemoLocationSource)?.speedMultiplier = accelerated ? 5 : 1 }
    }
    private var places: [Place] = []
    private var source: (any FreeRunLocationSource)?
    private var lastSampleAt: Date?
    private var loaded = false
    private let friendProvider: any FriendLocationProviding
    private var isRunning = false
    private var friendsRunning = false
    private var clockTask: Task<Void, Never>?

    init(isDemo: Bool, friendProvider: (any FriendLocationProviding)? = nil) {
        session = FreeRunSession(startedAt: .now, isDemo: isDemo)
        self.friendProvider = friendProvider ?? DemoFriendLocationProvider()
    }

    func start() {
        guard session.endedAt == nil, !isRunning else { return }
        if !loaded {
            do {
                places = try BundledJSON.load("taichung-bars")
                guard !places.isEmpty else { throw FreeRunDataError.empty }
                if let metadata: FreeRunMapAttributions = try? BundledJSON.load("taichung-data-metadata") {
                    mapAttributions = metadata.requiredAppAttributions
                }
                do {
                    let routes: [PopularRoute] = try BundledJSON.load("taichung-demo-popular-routes")
                    heatSegments = PopularRouteHeatmap.segments(from: routes)
                } catch {
                    heatmapError = "暫時無法載入熱門路線示範資料。"
                }
                if session.isDemo {
                    let routes: [PopularRoute] = try BundledJSON.load("taichung-demo-popular-routes")
                    guard let route = routes.first(where: { $0.id == "demo-route-01" }), route.path.count >= 2 else {
                        throw FreeRunDataError.empty
                    }
                    source = FreeRunDemoLocationSource(points: route.path)
                } else {
                    source = FreeRunDeviceLocationSource()
                }
                loaded = true
                dataError = nil
            } catch {
                dataError = "無法讀取酒吧或示範路徑：\(error.localizedDescription)"
                return
            }
        }
        isRunning = true
        clockTask?.cancel()
        clockTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                self?.tick()
            }
        }
        source?.start { [weak self] sample in
            guard let self else { return }
            now = .now
            lastSampleAt = sample.timestamp
            session.receive(sample, places: places, now: now)
            updateDemoTarget()
            if let coordinate = session.currentCoordinate {
                if !friendsRunning {
                    friendProvider.start { [weak self] in self?.friends = $0 }
                    friendsRunning = true
                }
                friendProvider.updateAnchor(coordinate, bars: Array(session.nearby.prefix(10)).map(\.place.coordinate))
            } else {
                stopFriends()
            }
        } onStatus: { [weak self] status in
            guard let self else { return }
            self.status = status
            if status == .denied || status == .unavailable {
                session.breakTracking()
                stopFriends()
                isRunning = false
            }
        }
        source?.onHeading = { [weak self] in self?.heading = $0 }
    }

    func tick() {
        now = .now
        if let lastSampleAt, now.timeIntervalSince(lastSampleAt) > 15 {
            session.breakTracking()
            stopFriends()
        }
    }

    func suspend() {
        source?.stop()
        clockTask?.cancel()
        clockTask = nil
        heading = nil
        isRunning = false
        stopFriends()
        lastSampleAt = nil
        session.breakTracking()
    }

    func record() {
        tick()
        guard let visit = session.record(at: now) else { return }
        lastRecordedName = visit.name
        feedbackCount += 1
        updateDemoTarget()
    }

    func selectBar(_ id: String) {
        session.selectBar(id)
        updateDemoTarget()
    }

    func togglePause() {
        now = .now
        if session.isPaused { session.resume(at: now) } else { session.pause(at: now) }
        (source as? FreeRunDemoLocationSource)?.isPaused = session.isPaused
    }

    private func updateDemoTarget() {
        (source as? FreeRunDemoLocationSource)?.target = session.activeBar?.place.coordinate
    }

    func finish() {
        suspend()
        now = .now
        session.finish(at: now)
    }

    private func stopFriends() {
        friendProvider.stop()
        friendsRunning = false
        friends = []
    }
}

private enum FreeRunDataError: LocalizedError {
    case empty
    var errorDescription: String? { "內附資料沒有可用的酒吧或路徑。" }
}
