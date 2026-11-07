import Foundation

struct SafeRideDemoEstimate {
    let distanceMeters: Double

    var amount: Int { 350 + Int((distanceMeters / 1_000 * 30).rounded(.up)) }

    init?(pickup: Waypoint?, destination: Waypoint) {
        guard let pickup, pickup.coordinate.isValid, destination.coordinate.isValid else { return nil }
        let start = pickup.coordinate
        let end = destination.coordinate
        let radians = Double.pi / 180
        let latitudeDelta = (end.latitude - start.latitude) * radians
        let longitudeDelta = (end.longitude - start.longitude) * radians
        let a = pow(sin(latitudeDelta / 2), 2)
            + cos(start.latitude * radians) * cos(end.latitude * radians) * pow(sin(longitudeDelta / 2), 2)
        distanceMeters = 6_371_000 * 2 * asin(sqrt(min(1, max(0, a))))
    }

    static let destinations: [Waypoint] = [
        Waypoint(id: "demo-station", name: "台中車站（範例）",
                 coordinate: Coordinate(latitude: 24.1370, longitude: 120.6869), placeId: nil),
        Waypoint(id: "demo-park", name: "秋紅谷（範例）",
                 coordinate: Coordinate(latitude: 24.1675, longitude: 120.6397), placeId: nil),
        Waypoint(id: "demo-calligraphy", name: "草悟道（範例）",
                 coordinate: Coordinate(latitude: 24.1511, longitude: 120.6639), placeId: nil)
    ]
}
