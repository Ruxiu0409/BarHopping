import Foundation

@MainActor
final class FreeRunDemoLocationSource: FreeRunLocationSource {
    var completedVisits = 0
    var waitsForFeedback = false
    private var task: Task<Void, Never>?
    var target: Coordinate?
    var onHeading: ((Double?) -> Void)?
    var isPaused = false
    private var journey: FreeRunDemoJourney

    init(origin: Coordinate) { journey = FreeRunDemoJourney(coordinate: origin) }

    func start(onSample: @escaping (FreeRunSample) -> Void, onStatus: @escaping (FreeRunLocationStatus) -> Void) {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
            var previousTime = Date.now
            while !Task.isCancelled {
                let now = Date.now
                let coordinate = journey.advance(toward: target, seconds: now.timeIntervalSince(previousTime),
                                                        completedVisits: completedVisits, isPaused: isPaused,
                                                        waitsForFeedback: waitsForFeedback)
                previousTime = now
                onSample(FreeRunSample(coordinate: coordinate, accuracy: 5, timestamp: .now))
                onStatus(.tracking)
                do { try await Task.sleep(for: .seconds(FreeRunDemoScript.sampleSeconds)) } catch { return }
            }
        }
    }

    func stop() { task?.cancel(); task = nil }
}
