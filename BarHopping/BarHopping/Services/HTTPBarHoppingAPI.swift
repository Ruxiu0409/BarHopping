import Foundation

/// HTTP API v1 用戶端（規格第 6 節）。所有失敗一律 throw `ServiceError`；
/// Task 被取消時 throw `CancellationError`，讓呼叫端忽略舊請求。
nonisolated struct HTTPBarHoppingAPI: BarHoppingAPI {
    static let requestTimeout: TimeInterval = 20

    let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = Self.requestTimeout
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.waitsForConnectivity = false
            self.session = URLSession(configuration: configuration)
        }
    }

    func config() async throws -> AppConfig {
        try await send(get(["v1", "config"]), clientRequestId: nil)
    }

    func places(in bbox: BoundingBox, query: String?, limit: Int, cursor: String?) async throws -> PlacesPage {
        var items = [URLQueryItem(name: "bbox", value: bbox.queryValue), URLQueryItem(name: "limit", value: String(limit))]
        if let q = query?.trimmingCharacters(in: .whitespacesAndNewlines), !q.isEmpty {
            items.append(URLQueryItem(name: "q", value: q))
        }
        if let cursor { items.append(URLQueryItem(name: "cursor", value: cursor)) }
        return try await send(get(["v1", "places"], query: items), clientRequestId: nil)
    }

    func place(id: String) async throws -> Place {
        try await send(get(["v1", "places", id]), clientRequestId: nil)
    }

    func previewRoute(_ request: RouteRequest) async throws -> RouteResult {
        var urlRequest = URLRequest(url: url(["v1", "routes", "preview"]))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.timeoutInterval = Self.requestTimeout
        do {
            urlRequest.httpBody = try JSONCoding.makeEncoder().encode(request)
        } catch {
            throw ServiceError(clientRequestId: request.clientRequestId, code: .invalidRequest,
                               message: "無法建立路線請求", retryable: false, waypointIds: [])
        }
        return try await send(urlRequest, clientRequestId: request.clientRequestId)
    }

    // MARK: - 請求

    private func url(_ segments: [String], query: [URLQueryItem] = []) -> URL {
        var url = baseURL
        for segment in segments { url.append(path: segment, directoryHint: .notDirectory) }
        guard !query.isEmpty, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        components.queryItems = query
        // URLComponents 不會編碼 "+"，伺服器可能把它當成空白。
        components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
        return components.url ?? url
    }

    private func get(_ segments: [String], query: [URLQueryItem] = []) -> URLRequest {
        var request = URLRequest(url: url(segments, query: query))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = Self.requestTimeout
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest, clientRequestId: String?) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Self.mapTransportError(error, clientRequestId: clientRequestId)
        }
        guard let http = response as? HTTPURLResponse else {
            throw ServiceError(clientRequestId: clientRequestId, code: .clientNetwork,
                               message: "伺服器回應格式不正確", retryable: true, waypointIds: [])
        }
        let decoder = JSONCoding.makeDecoder()
        guard (200..<300).contains(http.statusCode) else {
            throw Self.serviceError(status: http.statusCode, data: data, headers: http,
                                    clientRequestId: clientRequestId, decoder: decoder)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw ServiceError(clientRequestId: clientRequestId, code: .clientNetwork,
                               message: "無法解讀伺服器回應，請稍後再試", retryable: true, waypointIds: [])
        }
    }

    // MARK: - 錯誤對應

    static func mapTransportError(_ error: Error, clientRequestId: String?) -> Error {
        if error is CancellationError { return error }
        if let urlError = error as? URLError {
            if urlError.code == .cancelled { return CancellationError() }
            let message = switch urlError.code {
            case .timedOut: "連線逾時，請檢查網路後再試"
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed: "目前沒有網路連線，請連線後再試"
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed: "無法連線到伺服器，請稍後再試"
            default: "網路發生問題，請稍後再試"
            }
            return ServiceError(clientRequestId: clientRequestId, code: .clientNetwork,
                                message: message, retryable: true, waypointIds: [])
        }
        return ServiceError(clientRequestId: clientRequestId, code: .clientNetwork,
                            message: "網路發生問題，請稍後再試", retryable: true, waypointIds: [])
    }

    static func serviceError(status: Int, data: Data, headers: HTTPURLResponse,
                             clientRequestId: String?, decoder: JSONDecoder) -> ServiceError {
        var error: ServiceError
        if var decoded = try? decoder.decode(ServiceError.self, from: data) {
            if decoded.clientRequestId == nil { decoded.clientRequestId = clientRequestId }
            error = decoded
        } else {
            error = fallbackError(status: status, clientRequestId: clientRequestId)
        }
        if status == 429 || error.code == .rateLimited,
           let retryAfter = headers.value(forHTTPHeaderField: "Retry-After")?.trimmingCharacters(in: .whitespaces),
           !retryAfter.isEmpty {
            let hint = Int(retryAfter).map { "請在 \($0) 秒後再試" } ?? "請在 \(retryAfter) 後再試"
            error.message += "（\(hint)，Retry-After: \(retryAfter)）"
        }
        return error
    }

    static func fallbackError(status: Int, clientRequestId: String?) -> ServiceError {
        let (code, message): (ServiceErrorCode, String) = switch status {
        case 400: (.invalidRequest, "請求內容不正確")
        case 404: (.placeNotFound, "找不到指定的資料")
        case 422: (.noWalkableRoute, "無法規劃步行路線")
        case 429: (.rateLimited, "請求太頻繁")
        case 503: (.upstreamUnavailable, "路線服務暫時無法使用，請稍後再試")
        case 504: (.upstreamTimeout, "路線服務回應逾時，請稍後再試")
        case 500...599: (.upstreamUnavailable, "伺服器發生問題，請稍後再試")
        case 400...499: (.invalidRequest, "請求無法處理（HTTP \(status)）")
        default: (.clientNetwork, "伺服器回應異常（HTTP \(status)）")
        }
        let retryable = [.rateLimited, .upstreamUnavailable, .upstreamTimeout, .clientNetwork].contains(code)
        return ServiceError(clientRequestId: clientRequestId, code: code, message: message,
                            retryable: retryable, waypointIds: [])
    }
}
