import Foundation
import Observation
import SwiftUI
import UIKit

@MainActor @Observable
final class SafeRideLauncher {
    struct PhoneCall {
        let name: String
        let number: String
    }

    private(set) var pendingCall: PhoneCall?
    var showingPhoneConfirmation = false
    var showingError = false
    private(set) var errorMessage = ""

    func open(_ provider: SafeRideProvider, pickup: Waypoint?, destinationName: String,
              using openURL: OpenURLAction) {
        if case .phone(let number) = provider.openingMethod {
            requestPhoneCall(name: provider.name, number: number)
            return
        }
        launch(Self.url(for: provider.openingMethod, pickup: pickup,
                        destinationName: destinationName), using: openURL)
    }

    func requestPhoneCall(name: String, number: String) {
        pendingCall = PhoneCall(name: name, number: number)
        showingPhoneConfirmation = true
    }

    func confirmPhoneCall(using openURL: OpenURLAction) {
        guard let call = pendingCall else { return }
        pendingCall = nil
        launch(URL(string: "tel:\(call.number)"), using: openURL)
    }

    func openSettings(using openURL: OpenURLAction) {
        launch(URL(string: UIApplication.openSettingsURLString), using: openURL)
    }

    private func launch(_ url: URL?, using openURL: OpenURLAction) {
        guard let url else {
            reportFailure()
            return
        }
        openURL(url) { accepted in
            if !accepted {
                Task { @MainActor in self.reportFailure() }
            }
        }
    }

    private func reportFailure() {
        errorMessage = "目前無法開啟服務。請確認網路連線，或直接在手機開啟叫車 App。電話功能需使用可撥號的裝置。"
        showingError = true
    }

    static func url(for method: SafeRideProvider.OpeningMethod, pickup: Waypoint?,
                    destinationName: String = "", destination: Waypoint? = nil) -> URL? {
        switch method {
        case .appStore(let id):
            return URL(string: "https://apps.apple.com/tw/app/id\(id)")
        case .phone(let number):
            return URL(string: "tel:\(number)")
        case .uberUniversalLink:
            var components = URLComponents()
            components.scheme = "https"
            components.host = "m.uber.com"
            components.path = "/ul/"
            var items = [URLQueryItem(name: "action", value: "setPickup")]
            if let pickup, pickup.coordinate.isValid {
                items += locationItems(pickup, key: "pickup")
            } else {
                items.append(URLQueryItem(name: "pickup", value: "my_location"))
            }
            if let destination, destination.coordinate.isValid {
                items += locationItems(destination, key: "dropoff")
            } else {
                let name = destinationName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    items.append(URLQueryItem(name: "dropoff[nickname]", value: name))
                }
            }
            components.queryItems = items
            return components.url
        }
    }

    private static func locationItems(_ waypoint: Waypoint, key: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "\(key)[latitude]", value: String(waypoint.coordinate.latitude)),
            URLQueryItem(name: "\(key)[longitude]", value: String(waypoint.coordinate.longitude)),
            URLQueryItem(name: "\(key)[nickname]", value: waypoint.name)
        ]
    }
}
