import Foundation

struct DrinkPassPurchase: Identifiable {
    let id = UUID()
    let eventName: String
    let option: DrinkPassEvent.Option
    let quantity: Int
    let purchasedAt: Date
    let ticketNumber: String
    private(set) var redeemedCups = 0

    init(eventName: String, option: DrinkPassEvent.Option, quantity: Int,
         purchasedAt: Date = .now, ticketNumber: String = "DEMO-\(UUID().uuidString)") {
        self.eventName = eventName
        self.option = option
        self.quantity = quantity
        self.purchasedAt = purchasedAt
        self.ticketNumber = ticketNumber
    }

    var totalPrice: Int { option.price * quantity }
    var totalCups: Int { option.cups * quantity }
    var remainingCups: Int { max(0, totalCups - redeemedCups) }

    @discardableResult
    mutating func redeemCup() -> Bool {
        guard remainingCups > 0 else { return false }
        redeemedCups += 1
        return true
    }

}
