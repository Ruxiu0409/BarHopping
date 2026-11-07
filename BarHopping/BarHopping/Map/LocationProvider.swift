import CoreLocation
import Foundation

/// 前景單次定位。只在使用者按下定位相關按鈕時才請求權限。
/// 對外只回傳共用的 `Coordinate`。
@MainActor
final class LocationProvider: NSObject {
    nonisolated enum Problem: Error, Equatable {
        case denied
        case timeout
        case unavailable

        var message: String {
            switch self {
            case .denied: "沒有定位權限。你可以到「設定」開啟，或直接長按地圖選擇起點。"
            case .timeout: "暫時無法取得目前位置。你可以長按地圖選擇起點。"
            case .unavailable: "無法取得目前位置。你可以長按地圖選擇起點。"
            }
        }
    }

    static let timeout: Duration = .seconds(12)

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<Result<Coordinate, Problem>, Never>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestLocation() async -> Result<Coordinate, Problem> {
        if continuation != nil { finish(.failure(.unavailable)) }
        return await withCheckedContinuation { c in
            continuation = c
            timeoutTask = Task { [weak self] in
                try? await Task.sleep(for: Self.timeout)
                guard !Task.isCancelled else { return }
                self?.finish(.failure(.timeout))
            }
            handleAuthorization()
        }
    }

    private func handleAuthorization() {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            finish(.failure(.denied))
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        @unknown default:
            finish(.failure(.unavailable))
        }
    }

    private func finish(_ result: Result<Coordinate, Problem>) {
        timeoutTask?.cancel(); timeoutTask = nil
        guard let c = continuation else { return }
        continuation = nil
        c.resume(returning: result)
    }

    fileprivate func didUpdate(_ coordinate: Coordinate) { finish(.success(coordinate)) }

    fileprivate func didFail(denied: Bool) {
        if denied { finish(.failure(.denied)) }
        // 其他暫時性錯誤：等待逾時或下一次更新
    }

    fileprivate func authorizationChanged() { handleAuthorization() }
}

extension LocationProvider: CLLocationManagerDelegate {
    // CLLocationManager 在主執行緒建立，回呼也在主執行緒。
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated { self.authorizationChanged() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else { return }
        let c = Coordinate(latitude: last.coordinate.latitude, longitude: last.coordinate.longitude)
        MainActor.assumeIsolated { self.didUpdate(c) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        MainActor.assumeIsolated { self.didFail(denied: denied) }
    }
}
