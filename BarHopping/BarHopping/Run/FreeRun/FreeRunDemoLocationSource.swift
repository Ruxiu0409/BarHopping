import Foundation

@MainActor
final class FreeRunDemoLocationSource: FreeRunLocationSource {
    var speedMultiplier = 1.0
    private var path: FreeRunDemoPath
    private var task: Task<Void, Never>?
    var target: Coordinate?
    var onHeading: ((Double?) -> Void)?
    var isPaused = false
    private var journey: FreeRunDemoJourney?

    init(points: [Coordinate]) { path = FreeRunDemoPath(points: points) }

    func start(onSample: @escaping (FreeRunSample) -> Void, onStatus: @escaping (FreeRunLocationStatus) -> Void) {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if journey == nil {
                    guard let origin = path.advance(meters: 0) else {
                        onStatus(.unavailable)
                        return
                    }
                    journey = FreeRunDemoJourney(coordinate: origin)
                }
                guard let coordinate = journey?.advance(toward: target,
                                                        meters: FreeRunRules.demoMetersPerSecond * speedMultiplier,
                                                        isPaused: isPaused) else { return }
                onSample(FreeRunSample(coordinate: coordinate, accuracy: 5, timestamp: .now))
                onStatus(.tracking)
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }

    func stop() { task?.cancel(); task = nil }
}
