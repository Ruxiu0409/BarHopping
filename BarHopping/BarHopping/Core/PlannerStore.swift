import Foundation
import Observation
import SwiftUI

/// 地圖與路跑分頁共用的唯一一份目前 RoutePlan 與路線結果。
@MainActor @Observable
final class PlannerStore {
    enum ResultStatus: Equatable {
        case none
        case current              // 與目前規劃一致
        case stale                // 規劃已修改，路線需重新計算
        case savedEstimate        // 從草稿恢復，已儲存的估算
    }

    enum RoutingState: Equatable {
        case idle
        case computing
        case failed(ServiceError)
    }

    private(set) var plan: RoutePlan = .empty()
    private(set) var planVersion = 0
    private(set) var result: RouteResult?
    private(set) var resultStatus: ResultStatus = .none
    private(set) var routingState: RoutingState = .idle
    /// 給畫面顯示的一次性提示（超過八站、重複加入等）。
    var notice: String?

    let api: BarHoppingAPI
    let drafts: DraftStoring
    private var routingTask: Task<Void, Never>?
    private var inFlight: (requestId: String, version: Int)?

    init(api: BarHoppingAPI, drafts: DraftStoring) {
        self.api = api
        self.drafts = drafts
    }

    // MARK: - 編輯（每次編輯都使結果失效）

    private func edit(_ change: (inout RoutePlan) -> Void) {
        change(&plan)
        plan.updatedAt = .now
        planVersion += 1
        if result != nil { resultStatus = .stale }
        cancelRouting()
    }

    func setOrigin(_ waypoint: Waypoint?) { edit { $0.origin = waypoint } }

    func setReturnToOrigin() { edit { $0.endMode = .returnToOrigin; $0.destination = nil } }

    func setDestination(_ waypoint: Waypoint) { edit { $0.endMode = .custom; $0.destination = waypoint } }

    func setTitle(_ title: String) { edit { $0.title = title } }

    /// 加入酒吧；超過上限或重複 placeId 時不修改規劃並設定 notice。回傳是否成功。
    @discardableResult
    func addStop(_ waypoint: Waypoint, maxStops: Int = RoutePlan.maxStops) -> Bool {
        if plan.stops.count >= maxStops {
            notice = "每條路線最多 \(maxStops) 間酒吧"
            return false
        }
        if let pid = waypoint.placeId, plan.stops.contains(where: { $0.waypoint.placeId == pid }) {
            notice = "「\(waypoint.name)」已經在路線中"
            return false
        }
        edit { $0.stops.append(Stop(waypoint: waypoint, dwellMinutes: Stop.defaultDwellMinutes)) }
        return true
    }

    func contains(placeId: String) -> Bool { plan.stops.contains { $0.waypoint.placeId == placeId } }

    func removeStop(id: String) { edit { $0.stops.removeAll { $0.id == id } } }

    func moveStops(from source: IndexSet, to destination: Int) { edit { $0.stops.move(fromOffsets: source, toOffset: destination) } }

    func moveStop(id: String, by offset: Int) {
        guard let i = plan.stops.firstIndex(where: { $0.id == id }) else { return }
        let j = i + offset
        guard plan.stops.indices.contains(j) else { return }
        edit { $0.stops.swapAt(i, j) }
    }

    func setDwell(id: String, minutes: Int) {
        let m = min(max(minutes, Stop.dwellRange.lowerBound), Stop.dwellRange.upperBound)
        edit { p in
            if let i = p.stops.firstIndex(where: { $0.id == id }) { p.stops[i].dwellMinutes = m }
        }
    }

    /// 移動既有站點座標（例如 NO_WALKABLE_ROUTE 後修正）。
    func moveWaypoint(id: String, to coordinate: Coordinate) {
        edit { p in
            if p.origin?.id == id { p.origin?.coordinate = coordinate }
            if p.destination?.id == id { p.destination?.coordinate = coordinate }
            if let i = p.stops.firstIndex(where: { $0.id == id }) { p.stops[i].waypoint.coordinate = coordinate }
        }
    }

    func startNewPlan() {
        cancelRouting()
        plan = .empty(); planVersion += 1
        result = nil; resultStatus = .none; routingState = .idle
    }

    // MARK: - 計算路線

    var canCompute: Bool { plan.missingRequirements.isEmpty }

    func computeRoute() {
        guard canCompute else { return }
        cancelRouting()
        let requestId = UUID().uuidString
        let version = planVersion
        inFlight = (requestId, version)
        routingState = .computing
        let request = RouteRequest(clientRequestId: requestId, plan: plan)
        let api = self.api
        routingTask = Task { [weak self] in
            do {
                let r = try await api.previewRoute(request)
                self?.apply(.success(r), requestId: requestId, version: version)
            } catch is CancellationError {
                return
            } catch let e as ServiceError {
                self?.apply(.failure(e), requestId: requestId, version: version)
            } catch {
                let e = ServiceError(clientRequestId: requestId, code: .clientNetwork,
                                     message: "無法連線，請稍後再試", retryable: true, waypointIds: [])
                self?.apply(.failure(e), requestId: requestId, version: version)
            }
        }
    }

    /// 只有 requestId 與規劃版本仍符合時才套用，避免較晚抵達的舊請求覆蓋新規劃。
    private func apply(_ outcome: Result<RouteResult, ServiceError>, requestId: String, version: Int) {
        guard let f = inFlight, f.requestId == requestId, f.version == version, planVersion == version else { return }
        inFlight = nil
        switch outcome {
        case .success(let r) where r.clientRequestId == requestId:
            result = r; resultStatus = .current; routingState = .idle
        case .success:
            return
        case .failure(let e):
            routingState = .failed(e)
        }
    }

    func cancelRouting() {
        routingTask?.cancel(); routingTask = nil; inFlight = nil
        if routingState == .computing { routingState = .idle }
    }

    // MARK: - 草稿

    func saveDraft() async throws {
        let attached = resultStatus == .current || resultStatus == .savedEstimate ? result : nil
        try await drafts.save(SavedDraft(plan: plan, result: attached, savedAt: .now))
    }

    func load(_ draft: SavedDraft) {
        cancelRouting()
        plan = draft.plan; planVersion += 1
        result = draft.result
        resultStatus = draft.result == nil ? .none : .savedEstimate
        routingState = .idle
    }
}
