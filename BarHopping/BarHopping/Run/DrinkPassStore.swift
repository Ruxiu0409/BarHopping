import Observation

@MainActor @Observable
final class DrinkPassStore {
    private(set) var purchases: [DrinkPassPurchase] = []

    func record(_ purchase: DrinkPassPurchase) {
        guard !purchases.contains(where: { $0.id == purchase.id }) else { return }
        purchases.append(purchase)
    }
}
