import Foundation

@MainActor
final class DemoFriendLocationProvider: FriendLocationProviding {
    private var anchor: Coordinate?
    private var bars: [Coordinate] = []
    private var motion = DemoFriendMotion()
    private var task: Task<Void, Never>?

    func start(onLocations: @escaping ([FriendLocation]) -> Void) {
        stop()
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                if let anchor {
                    onLocations(motion.locations(around: anchor, bars: bars, at: .now))
                }
                do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
            }
        }
    }

    func updateAnchor(_ coordinate: Coordinate, bars: [Coordinate]) {
        anchor = coordinate
        self.bars = bars
    }

    func stop() {
        task?.cancel()
        task = nil
        anchor = nil
        motion = DemoFriendMotion()
    }
}
