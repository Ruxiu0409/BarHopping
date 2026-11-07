import Foundation
import Observation

@MainActor @Observable
final class DrinkPassStore {
    private(set) var purchases: [DrinkPassPurchase] = []

    private var redeemedVisitIDs: Set<UUID> = []

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
