import Foundation

@MainActor
final class FreeRunDemoLocationSource: FreeRunLocationSource {
    var speedMultiplier = 1.0
    private var path: FreeRunDemoPath
    private var task: Task<Void, Never>?

    init(points: [Coordinate]) { path = FreeRunDemoPath(points: points) }

    func start(onSample: @escaping (FreeRunSample) -> Void, onStatus: @escaping (FreeRunLocationStatus) -> Void) {
        stop()
        task = Task { [weak self] in
            guard let self else { return }
            var first = true
            while !Task.isCancelled {
                guard let coordinate = path.advance(meters: first ? 0 : FreeRunRules.demoMetersPerSecond * speedMultiplier) else {
                    onStatus(.unavailable)
                    return
                }
                first = false
                onSample(FreeRunSample(coordinate: coordinate, accuracy: 5, timestamp: .now))
                onStatus(path.isFinished ? .demoFinished : .tracking)
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
    }

    func stop() { task?.cancel(); task = nil }
}
