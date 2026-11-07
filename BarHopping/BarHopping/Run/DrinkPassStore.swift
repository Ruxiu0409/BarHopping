import Foundation
import Observation

@MainActor @Observable
final class DrinkPassStore {
    static let seedsDemoPurchase = true

    private(set) var purchases: [DrinkPassPurchase] = []

    private var redeemedVisitIDs: Set<UUID> = []

    init() {
        let event = DrinkPassMockData.event
        guard Self.seedsDemoPurchase,
              let option = event.options.first(where: { $0.id == "single" }) ?? event.options.first else { return }
        purchases = [DrinkPassPurchase(
            eventName: event.name,
            option: option,
            quantity: 1,
            purchasedAt: Date.now.addingTimeInterval(-24 * 60 * 60),
            ticketNumber: "LS9Z-2026-0001"
        )]
    }

    func record(_ purchase: DrinkPassPurchase) {
        guard !purchases.contains(where: { $0.id == purchase.id }) else { return }
        purchases.append(purchase)
    }
    @discardableResult
    func redeemCup(purchaseID: UUID, visitID: UUID) -> Bool {
        guard !redeemedVisitIDs.contains(visitID),
              let index = purchases.firstIndex(where: { $0.id == purchaseID }),
              purchases[index].redeemCup() else { return false }
        redeemedVisitIDs.insert(visitID)
        return true
    }
}
