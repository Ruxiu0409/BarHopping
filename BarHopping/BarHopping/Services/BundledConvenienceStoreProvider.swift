import Foundation

nonisolated struct BundledConvenienceStoreProvider: ConvenienceStoreProviding {
    /// Immutable, lazily initialized once across all provider instances, including failures.
    private static let cachedStores: Result<[ConvenienceStore], Error> = Result {
        try BundledJSON.load("taichung-convenience-stores")
    }

    func stores(in bbox: BoundingBox, brands: Set<ConvenienceBrand>) async throws -> [ConvenienceStore] {
        guard [bbox.west, bbox.south, bbox.east, bbox.north].allSatisfy(\.isFinite),
              (-180...180).contains(bbox.west), (-180...180).contains(bbox.east),
              (-90...90).contains(bbox.south), (-90...90).contains(bbox.north),
              bbox.west <= bbox.east, bbox.south <= bbox.north else {
            throw ServiceError(clientRequestId: nil, code: .invalidRequest,
                               message: "超商查詢 bbox 格式不正確，需為 west,south,east,north",
                               retryable: false, waypointIds: [])
        }
        try Task.checkCancellation()
        return try Self.cachedStores.get().filter {
            bbox.contains($0.coordinate) && (brands.isEmpty || brands.contains($0.brand))
        }
    }
}
