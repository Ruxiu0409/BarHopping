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
    var accelerated = false {
        didSet { (source as? FreeRunDemoLocationSource)?.speedMultiplier = accelerated ? 5 : 1 }
    }
    private var places: [Place] = []
    private var source: (any FreeRunLocationSource)?
    private var lastSampleAt: Date?
    private var loaded = false

    init(isDemo: Bool) { session = FreeRunSession(startedAt: .now, isDemo: isDemo) }

    func start() {
        guard session.endedAt == nil else { return }
        if !loaded {
            do {
                places = try BundledJSON.load("taichung-bars")
                guard !places.isEmpty else { throw FreeRunDataError.empty }
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
        source?.start { [weak self] sample in
            guard let self else { return }
            now = .now
            lastSampleAt = sample.timestamp
            session.receive(sample, places: places, now: now)
        } onStatus: { [weak self] status in
            guard let self else { return }
            self.status = status
            if status == .denied || status == .unavailable { session.breakTracking() }
        }
    }

    func tick() {
        now = .now
        if let lastSampleAt, now.timeIntervalSince(lastSampleAt) > 15 { session.breakTracking() }
    }

    func suspend() {
        source?.stop()
        lastSampleAt = nil
        session.breakTracking()
    }

    func record() {
        tick()
        guard let visit = session.record(at: now) else { return }
        lastRecordedName = visit.name
        feedbackCount += 1
    }

    func selectBar(_ id: String) { session.selectBar(id) }

    func finish() {
        source?.stop()
        now = .now
        session.finish(at: now)
    }
}

private enum FreeRunDataError: LocalizedError {
    case empty
    var errorDescription: String? { "內附資料沒有可用的酒吧或路徑。" }
}
