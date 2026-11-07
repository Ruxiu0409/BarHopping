import Foundation

struct DrinkPassPurchase: Identifiable {
    let id = UUID()
    let eventName: String
    let option: DrinkPassEvent.Option
    let quantity: Int
    private(set) var redeemedCups = 0

    var totalPrice: Int { option.price * quantity }
    var totalCups: Int { option.cups * quantity }
    var remainingCups: Int { max(0, totalCups - redeemedCups) }

    @discardableResult
    mutating func redeemCup() -> Bool {
        guard remainingCups > 0 else { return false }
        redeemedCups += 1
        return true
    }

    var ticketNumber: String { "DEMO-\(id.uuidString)" }
}
