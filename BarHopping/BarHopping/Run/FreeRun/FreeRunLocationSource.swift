import CoreLocation
import Foundation

nonisolated enum FreeRunLocationStatus: Equatable {
    case waiting, tracking, denied, unavailable, demoFinished
}

@MainActor
protocol FreeRunLocationSource: AnyObject {
    func start(onSample: @escaping (FreeRunSample) -> Void, onStatus: @escaping (FreeRunLocationStatus) -> Void)
    func stop()
}

@MainActor
final class FreeRunDeviceLocationSource: NSObject, FreeRunLocationSource, CLLocationManagerDelegate {
    private let permissionProvider = LocationProvider()
    private let manager = CLLocationManager()
    private var permissionTask: Task<Void, Never>?
    private var onSample: ((FreeRunSample) -> Void)?
    private var onStatus: ((FreeRunLocationStatus) -> Void)?
    private var isRunning = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
    }

    func start(onSample: @escaping (FreeRunSample) -> Void, onStatus: @escaping (FreeRunLocationStatus) -> Void) {
        stop()
        self.onSample = onSample
        self.onStatus = onStatus
        isRunning = true
        onStatus(.waiting)
        permissionTask = Task { [weak self] in
            guard let self else { return }
            let result = await permissionProvider.requestLocation()
            guard !Task.isCancelled, isRunning else { return }
            switch result {
            case .success: updateAuthorization()
            case .failure(.denied): onStatus(.denied)
            case .failure: updateAuthorization()
            }
        }
    }

    func stop() {
        isRunning = false
        permissionTask?.cancel()
        permissionTask = nil
        manager.stopUpdatingLocation()
        onSample = nil
        onStatus = nil
    }

    private func updateAuthorization() {
        guard isRunning else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            manager.stopUpdatingLocation()
            onStatus?(.denied)
        case .notDetermined: break // 權限提示沿用 LocationProvider。
        @unknown default: onStatus?(.unavailable)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated { updateAuthorization() }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            guard isRunning else { return }
            for location in locations {
                onSample?(FreeRunSample(coordinate: Coordinate(latitude: location.coordinate.latitude,
                                                               longitude: location.coordinate.longitude),
                                        accuracy: location.horizontalAccuracy, timestamp: location.timestamp))
            }
            onStatus?(.tracking)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        MainActor.assumeIsolated {
            guard isRunning else { return }
            onStatus?(denied ? .denied : .unavailable)
        }
    }
}
