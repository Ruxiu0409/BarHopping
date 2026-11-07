import Foundation

nonisolated struct BundledPopularRouteProvider: PopularRouteProviding {
    private static let cachedRoutes: Result<[PopularRoute], Error> = Result {
        try BundledJSON.load("taichung-demo-popular-routes")
    }

    func routes() async throws -> [PopularRoute] {
        try Task.checkCancellation()
        return try Self.cachedRoutes.get()
    }
}
