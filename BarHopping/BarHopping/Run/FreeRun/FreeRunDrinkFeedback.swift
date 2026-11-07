import Foundation

nonisolated struct FreeRunDrinkFeedback: Identifiable {
    enum Phase { case celebrating, scanning, success, complete }

    let id: UUID
    let showsTicket: Bool
    private(set) var elapsed = 0.0

    var phase: Phase {
        if showsTicket {
            if elapsed < FreeRunDemoScript.scanSeconds { return .scanning }
            if elapsed < FreeRunDemoScript.scanSeconds + FreeRunDemoScript.successSeconds { return .success }
        } else if elapsed < FreeRunDemoScript.confettiSeconds {
            return .celebrating
        }
        return .complete
    }

    mutating func advance(seconds: Double) { elapsed += max(0, seconds) }
}
