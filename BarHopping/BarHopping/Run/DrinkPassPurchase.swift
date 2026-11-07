import Foundation

struct DrinkPassPurchase: Identifiable {
    let id = UUID()
    let option: DrinkPassEvent.Option
    let quantity: Int

    var totalPrice: Int { option.price * quantity }
    var totalCups: Int { option.cups * quantity }
    var ticketNumber: String { "DEMO-\(id.uuidString)" }
}
