import Foundation

/// Xcode folder synchronization may flatten resources or preserve their directories.
nonisolated enum BundledJSON {
    static func load<T: Decodable>(_ name: String, bundle: Bundle = .main) throws -> T {
        let url = [nil, "Data", "Resources/Data"].lazy.compactMap {
            bundle.url(forResource: name, withExtension: "json", subdirectory: $0)
        }.first
        guard let url else {
            throw failure("找不到 App 內附資料 \(name).json，請重新安裝 App")
        }
        do {
            return try JSONCoding.makeDecoder().decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw failure("無法讀取 App 內附資料 \(name).json：\(error.localizedDescription)")
        }
    }

    private static func failure(_ message: String) -> ServiceError {
        ServiceError(clientRequestId: nil, code: .upstreamUnavailable,
                     message: message, retryable: false, waypointIds: [])
    }
}
