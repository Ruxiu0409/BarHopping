import Foundation
import Observation

@MainActor @Observable
final class SafeRidePickupStore {
    enum Status {
        case locating
        case located(Coordinate)
        case failed
    }

    private(set) var status: Status = .locating
    private(set) var failureMessage = ""
    private let provider = LocationProvider()
    private var requestInFlight = false

    var pickup: Waypoint? {
        guard case .located(let coordinate) = status else { return nil }
        return Waypoint(id: "safe-ride-current-location", name: "目前位置",
                        coordinate: coordinate, placeId: nil)
    }

    var hasFailed: Bool {
        if case .failed = status { return true }
        return false
    }

    func request() async {
        guard !requestInFlight else { return }
        requestInFlight = true
        status = .locating
        defer { requestInFlight = false }
        let result = await provider.requestLocation()
        switch result {
        case .success(let coordinate) where coordinate.isValid:
            status = .located(coordinate)
        case .success:
            fail("取得的位置無效。叫車服務仍可自行定位。")
        case .failure(.denied):
            fail("尚未允許定位。請到設定開啟，或直接讓叫車服務自行定位。")
        case .failure(.timeout):
            fail("取得位置逾時。可重試或前往設定檢查定位，叫車服務仍可使用。")
        case .failure(.unavailable):
            fail("暫時無法取得位置。可前往設定檢查定位，叫車服務仍可使用。")
        }
    }

    private func fail(_ message: String) {
        failureMessage = message
        status = .failed
    }
}
