import Foundation
import Observation

@MainActor @Observable
final class FreeRunStore {
    private(set) var hasEnded = false
    private(set) var hasArrived = false
    private(set) var feedbackID: UUID?
    private(set) var feedbackShowsTicket = false
    private(set) var session: FreeRunSession
    private(set) var status: FreeRunLocationStatus = .waiting
    private(set) var dataError: String?
    private(set) var now = Date.now
    private(set) var lastRecordedName: String?
    private(set) var feedbackCount = 0
    private(set) var friends: [FriendLocation] = []
    private(set) var heading: Double?
    private(set) var heatmap: FreeRunHeatmapContent?
    private(set) var heatmapError: String?
    private(set) var mapAttributions: [String] = []
    private(set) var drinkFeedback: FreeRunDrinkFeedback?
    private(set) var scanTicket: DrinkPassPurchase?
    private(set) var isDemoTicket = false
    private(set) var didRedeemCup = false
    private var demoTicket = DrinkPassPurchase(eventName: DrinkPassMockData.event.name,
                                              option: DrinkPassMockData.event.options[0], quantity: 1)
    private var drinkTask: Task<Void, Never>?
    private var places: [Place] = []
    private var source: (any FreeRunLocationSource)?
    private var lastSampleAt: Date?
    private var loaded = false
    private let friendProvider: any FriendLocationProviding
    private var isRunning = false
    private var friendsRunning = false
    private var heatmapTask: Task<Void, Never>?
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
                heatmapTask = Task { [weak self] in
                    do {
                        let segments = try await FreeRunHeatmapCache.segments.value
                        self?.heatmap = FreeRunHeatmapContent(segments: segments)
                    } catch {
                        self?.heatmapError = "暫時無法載入熱門路線示範資料。"
                    }
                }
                if session.isDemo {
                    let routes: [PopularRoute] = try BundledJSON.load("taichung-demo-popular-routes")
                    guard let route = routes.first(where: { $0.path.count >= 2 }),
                          let origin = FreeRunDemoScript.startCoordinate(on: route.path, places: places) else {
                        throw FreeRunDataError.empty
                    }
                    source = FreeRunDemoLocationSource(origin: origin)
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
            lastSampleAt = sample.timestamp
            if session.isDemo, sample.coordinate == session.currentCoordinate, session.hasAccurateLocation { return }
            session.receive(sample, places: places, now: .now)
            syncArrival()
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
            if self.status != status { self.status = status }
            if status == .denied || status == .unavailable {
                session.breakTracking()
                syncArrival()
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
            syncArrival()
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
        syncArrival()
    }

    func record(using passes: DrinkPassStore) {
        guard drinkFeedback == nil || !session.isDemo else { return }
        tick()
        let showsTicket = session.isDemo && session.activeBar?.place.category == .bar
        guard let visit = session.record(at: now) else { return }
        drinkTask?.cancel()
        drinkFeedback = FreeRunDrinkFeedback(id: visit.id, showsTicket: showsTicket)
        feedbackID = visit.id
        feedbackShowsTicket = showsTicket
        syncArrival()
        didRedeemCup = false
        if showsTicket {
            let purchased = passes.purchases.first { $0.remainingCups > 0 } ?? passes.purchases.first
            isDemoTicket = purchased == nil
            scanTicket = purchased ?? demoTicket
        }
        lastRecordedName = visit.name
        feedbackCount += 1
        updateDemoTarget()
        drinkTask = Task { [weak self] in
            var previous = Date.now
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(FreeRunDemoScript.feedbackSampleSeconds)) } catch { return }
                guard let self, var feedback = drinkFeedback else { return }
                let now = Date.now
                let oldPhase = feedback.phase
                feedback.advance(seconds: now.timeIntervalSince(previous))
                previous = now
                // 即使 App 暫時沒有取得執行時間，也只跨過一次核銷邊界。
                if showsTicket, oldPhase == .scanning, feedback.elapsed >= FreeRunDemoScript.scanSeconds {
                    if isDemoTicket {
                        didRedeemCup = demoTicket.redeemCup()
                        scanTicket = demoTicket
                    } else if let ticket = scanTicket {
                        didRedeemCup = passes.redeemCup(purchaseID: ticket.id, visitID: visit.id)
                        scanTicket = passes.purchases.first { $0.id == ticket.id }
                    }
                }
                drinkFeedback = feedback
                if feedback.phase == .complete {
                    completeDrinkFeedback()
                    return
                }
            }
        }
    }

    func completeDrinkFeedback() {
        guard let feedback = drinkFeedback, feedback.phase != .scanning else { return }
        drinkTask?.cancel()
        drinkTask = nil
        drinkFeedback = nil
        feedbackID = nil
        feedbackShowsTicket = false
        scanTicket = nil
        updateDemoTarget()
    }

    func selectBar(_ id: String) {
        session.selectBar(id)
        syncArrival()
        updateDemoTarget()
    }

    func togglePause() {
        now = .now
        if session.isPaused { session.resume(at: now) } else { session.pause(at: now) }
        syncArrival()
        (source as? FreeRunDemoLocationSource)?.isPaused = session.isPaused
    }

    private func updateDemoTarget() {
        guard let demo = source as? FreeRunDemoLocationSource else { return }
        demo.target = session.activeBar?.place.coordinate
        demo.completedVisits = session.uniqueBarCount
        demo.waitsForFeedback = drinkFeedback != nil
    }

    func finish() {
        drinkTask?.cancel()
        drinkTask = nil
        drinkFeedback = nil
        feedbackID = nil
        feedbackShowsTicket = false
        suspend()
        now = .now
        session.finish(at: now)
        hasEnded = true
    }

    private func syncArrival() {
        if hasArrived != session.hasArrived { hasArrived = session.hasArrived }
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
