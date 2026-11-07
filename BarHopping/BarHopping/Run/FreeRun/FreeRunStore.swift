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

    func record(using passes: DrinkPassStore) {
        guard drinkFeedback == nil || !session.isDemo else { return }
        tick()
        let showsTicket = session.isDemo && session.activeBar?.place.category == .bar
        guard let visit = session.record(at: now) else { return }
        drinkTask?.cancel()
        drinkFeedback = FreeRunDrinkFeedback(id: visit.id, showsTicket: showsTicket)
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
                do { try await Task.sleep(for: .seconds(FreeRunDemoScript.sampleSeconds)) } catch { return }
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
        scanTicket = nil
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
        guard let demo = source as? FreeRunDemoLocationSource else { return }
        demo.target = session.activeBar?.place.coordinate
        demo.completedVisits = session.uniqueBarCount
        demo.waitsForFeedback = drinkFeedback != nil
    }

    func finish() {
        drinkTask?.cancel()
        drinkTask = nil
        drinkFeedback = nil
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
