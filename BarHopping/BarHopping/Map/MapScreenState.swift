import Foundation
import Observation
import SwiftUI

/// 地圖分頁自己的畫面狀態（視角、搜尋條件與結果、選取、底圖狀態）。
/// 由 `MapTabView` 以 `@State` 持有，切換分頁再回來時保留。RoutePlan 一律在 `PlannerStore`。
@MainActor @Observable
final class MapScreenState {
    // MARK: 視角

    struct Camera: Equatable {
        var center: Coordinate
        var zoom: Double
    }

    /// 地圖目前視角（由地圖回報；不驅動畫面更新）。
    @ObservationIgnored var camera = Camera(center: MockFixtures.cityCenter, zoom: 13)
    /// 地圖目前可視範圍（由地圖回報）。
    @ObservationIgnored var visibleBounds: BoundingBox?
    /// 上方與下方浮動元件的高度，框選路線時避開。
    @ObservationIgnored var overlayInsets = EdgeInsets(top: 140, leading: 40, bottom: 240, trailing: 40)

    /// 交給地圖執行一次的鏡頭指令。
    struct CameraCommand: Equatable {
        enum Kind: Equatable {
            case fit([Coordinate])
            case center(Coordinate, zoom: Double?)
        }
        var id: Int
        var kind: Kind
    }
    private(set) var cameraCommand: CameraCommand?
    private var nextCommandId = 0
    /// 已處理過的 `AppRouter.mapFocusRouteRequest`。
    @ObservationIgnored var handledRouterFocus = 0

    func send(_ kind: CameraCommand.Kind) {
        nextCommandId += 1
        cameraCommand = CameraCommand(id: nextCommandId, kind: kind)
    }

    // MARK: 底圖

    static let fallbackStyleURL = URL(string: "https://tiles.openfreemap.org/styles/dark")!
    static let bundledDataAttributions = [
        Attribution(text: "財政部稅籍登記資料", url: URL(string: "https://data.gov.tw/dataset/9400")!),
        Attribution(text: "環境部 Cool Map", url: URL(string: "https://data.gov.tw/dataset/177893")!),
        Attribution(text: "政府資料開放授權條款第 1 版", url: URL(string: "https://data.gov.tw/license")!),
    ]
    static let popularRouteAttribution = Attribution(
        text: "路徑：FOSSGIS 步行路由", url: URL(string: "https://routing.openstreetmap.de/")!)

    static let fallbackAttributions = [
        Attribution(text: "© OpenStreetMap contributors", url: URL(string: "https://www.openstreetmap.org/copyright")!),
        Attribution(text: "OpenFreeMap", url: URL(string: "https://openfreemap.org")!),
        Attribution(text: "© OpenMapTiles", url: URL(string: "https://www.openmaptiles.org/")!),
    ] + bundledDataAttributions

    private(set) var config: AppConfig?
    private(set) var styleURL: URL = MapScreenState.fallbackStyleURL
    private(set) var attributions: [Attribution] = MapScreenState.fallbackAttributions
    private var configTask: Task<Void, Never>?
    private var configLoaded = false

    var mapLoadError: String?
    /// 遞增時地圖重新載入 style。
    private(set) var styleReloadToken = 0
    var showsUserLocation = false

    var maxStops: Int { config?.maxStops ?? RoutePlan.maxStops }

    func loadConfigIfNeeded(api: BarHoppingAPI) {
        guard !configLoaded, configTask == nil else { return }
        configTask = Task { [weak self] in
            let result: AppConfig?
            do { result = try await api.config() } catch { result = nil }
            guard let self else { return }
            self.configTask = nil
            guard let result else { return }   // 取不到時沿用預設 style 與標示，下次進入再試
            self.configLoaded = true
            self.config = result
            self.styleURL = result.mapStyleUrl
            var list = result.attributions
            if !list.contains(where: { $0.text.localizedCaseInsensitiveContains("OpenStreetMap") }) {
                list.insert(Self.fallbackAttributions[0], at: 0)
            }
            for attribution in Self.bundledDataAttributions where !list.contains(where: { $0.url == attribution.url }) {
                list.append(attribution)
            }
            self.attributions = list
        }
    }

    func retryMapLoad() {
        mapLoadError = nil
        styleReloadToken += 1
    }

    // MARK: 熱門路線

    private(set) var popularSegments: [PopularRouteSegment] = []
    private(set) var popularRoutesError: String?
    @ObservationIgnored private var popularRoutesTask: Task<Void, Never>?
    @ObservationIgnored private let popularRouteProvider = AppEnvironment.makePopularRouteProvider()

    func loadPopularRoutesIfNeeded() {
        guard popularRoutesTask == nil else { return }
        let provider = popularRouteProvider
        popularRoutesTask = Task { [weak self] in
            do {
                let segments = try await Task.detached(priority: .utility) {
                    PopularRouteHeatmap.segments(from: try await provider.routes())
                }.value
                self?.popularSegments = segments
            } catch {
                self?.popularRoutesError = "熱門路線示範資料載入失敗"
            }
        }
    }

    // MARK: 搜尋

    enum SearchStatus: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    var queryText = ""
    var categoryFilter: PlaceCategory?
    var listExpanded = false

    private(set) var places: [Place] = []
    private(set) var searchStatus: SearchStatus = .idle
    @ObservationIgnored private var placesTask: Task<Void, Never>?

    static let pageSize = 50

    var visiblePlaces: [Place] {
        let query = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        return places.filter { place in
            (categoryFilter == nil || place.category == categoryFilter)
                && (query.isEmpty || place.name.range(of: query, options: [
                    .caseInsensitive, .diacriticInsensitive, .widthInsensitive,
                ]) != nil)
        }
    }

    func submitSearch() {
        selection = nil
        listExpanded = true
    }

    /// 首次進入載入整個服務範圍；之後搜尋與分類都只篩選記憶體中的完整目錄。
    func loadPlacesIfNeeded(api: BarHoppingAPI) {
        guard searchStatus != .loaded, placesTask == nil else { return }
        searchStatus = .loading
        placesTask = Task { [weak self] in
            guard let self else { return }
            defer { self.placesTask = nil }
            do {
                let area: GeoJSONPolygon
                if let config = self.config {
                    area = config.serviceArea
                } else {
                    area = try await api.config().serviceArea
                }
                let coordinates = area.coordinates.flatMap { $0 }
                guard let west = coordinates.map({ $0[0] }).min(),
                      let east = coordinates.map({ $0[0] }).max(),
                      let south = coordinates.map({ $0[1] }).min(),
                      let north = coordinates.map({ $0[1] }).max() else {
                    throw ServiceError(clientRequestId: nil, code: .upstreamUnavailable,
                                       message: "無法讀取台中服務範圍", retryable: true, waypointIds: [])
                }
                let bounds = BoundingBox(west: west, south: south, east: east, north: north)
                var allPlaces: [Place] = []
                var knownIDs: Set<String> = []
                var cursor: String?
                var seenCursors: Set<String> = []
                repeat {
                    let page = try await api.places(in: bounds, query: nil,
                                                    limit: Self.pageSize, cursor: cursor)
                    try Task.checkCancellation()
                    allPlaces += page.items.filter { knownIDs.insert($0.id).inserted }
                    cursor = page.nextCursor
                    if let cursor, !seenCursors.insert(cursor).inserted {
                        throw ServiceError(clientRequestId: nil, code: .upstreamUnavailable,
                                           message: "酒吧資料載入不完整，請重試", retryable: true, waypointIds: [])
                    }
                } while cursor != nil
                self.places = allPlaces
                self.searchStatus = .loaded
            } catch is CancellationError {
                self.searchStatus = .idle
            } catch {
                self.searchStatus = .failed(Self.message(for: error))
            }
        }
    }

    static func message(for error: Error) -> String {
        guard let e = error as? ServiceError else { return "無法連線，請稍後再試" }
        switch e.code {
        case .rateLimited: return "請求太頻繁，請稍候再試"
        case .upstreamUnavailable: return e.message.isEmpty ? "服務暫時無法使用，請稍後再試" : e.message
        case .upstreamTimeout: return "服務回應逾時，請稍後再試"
        case .outsideServiceArea: return "這個範圍不在服務區域內"
        default: return e.message.isEmpty ? "搜尋失敗，請稍後再試" : e.message
        }
    }

    // MARK: 超商圖層

    static let convenienceMinimumZoom = 14.0
    var showsConvenienceStores = false
    var convenienceBrand: ConvenienceBrand?
    private(set) var convenienceStores: [ConvenienceStore] = []
    private(set) var convenienceStatus: ConvenienceStatus = .zoomIn
    @ObservationIgnored private let convenienceProvider = AppEnvironment.makeConvenienceStoreProvider()
    @ObservationIgnored private var convenienceTask: Task<Void, Never>?
    @ObservationIgnored private var convenienceToken = 0

    enum ConvenienceStatus: Equatable {
        case zoomIn, loading, loaded, failed
    }

    var convenienceStatusText: String {
        switch convenienceStatus {
        case .zoomIn: "放大地圖即可顯示超商"
        case .loading: "正在載入超商…"
        case .loaded: convenienceStores.isEmpty ? "這個範圍沒有超商資料" : "目前範圍 \(convenienceStores.count) 間超商"
        case .failed: "超商資料載入失敗，點此重試"
        }
    }

    func toggleConvenienceStores() {
        showsConvenienceStores.toggle()
        refreshConvenienceStores()
    }

    func filterConvenienceStores(_ brand: ConvenienceBrand?) {
        convenienceBrand = brand
        convenienceStores = []
        if case .convenienceStore = selection { selection = nil }
        refreshConvenienceStores()
    }

    func cancelConvenienceQuery() {
        convenienceTask?.cancel()
        convenienceTask = nil
        convenienceToken += 1
    }

    /// 只由地圖停止移動、開關與品牌切換觸發。取消與 token 一起防止舊結果覆蓋。
    func refreshConvenienceStores() {
        cancelConvenienceQuery()
        guard showsConvenienceStores, camera.zoom >= Self.convenienceMinimumZoom else {
            convenienceStores = []
            convenienceStatus = .zoomIn
            if case .convenienceStore = selection { selection = nil }
            return
        }
        guard let bbox = visibleBounds else { return }
        convenienceStatus = .loading
        let token = convenienceToken
        let brands = Set(convenienceBrand.map { [$0] } ?? [])
        let provider = convenienceProvider
        convenienceTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(300))
                let stores = try await provider.stores(in: bbox, brands: brands)
                try Task.checkCancellation()
                guard let self, self.convenienceToken == token else { return }
                self.convenienceStores = stores
                self.convenienceStatus = .loaded
                self.convenienceTask = nil
                if case .convenienceStore(let selected) = self.selection,
                   !stores.contains(where: { $0.id == selected.id }) {
                    self.selection = nil
                }
            } catch is CancellationError {
                return
            } catch {
                guard let self, self.convenienceToken == token else { return }
                self.convenienceStores = []
                self.convenienceStatus = .failed
                self.convenienceTask = nil
            }
        }
    }

    // MARK: 選取

    enum Selection: Equatable {
        case place(Place)
        case waypoint(String)
        case convenienceStore(ConvenienceStore)
    }
    var selection: Selection?

    func select(_ place: Place, moveCamera: Bool) {
        selection = .place(place)
        listExpanded = false
        if moveCamera { send(.center(place.coordinate, zoom: max(camera.zoom, 15))) }
    }

    // MARK: 長按 / 自訂站點

    /// 長按的位置（顯示暫時標記與選單）。
    var pendingCoordinate: Coordinate?

    // MARK: 定位

    @ObservationIgnored private var attemptedInitialLocation = false
    @ObservationIgnored var hasInteractedWithMap = false
    @ObservationIgnored var isMapVisible = false
    @ObservationIgnored var permitsInitialLocationCamera = true

    func locateOnFirstAppearance(planner: PlannerStore) {
        isMapVisible = true
        guard !attemptedInitialLocation else { return }
        attemptedInitialLocation = true
        guard !isLocating else { return }
        let commandId = nextCommandId
        let initialPlan = planner.plan
        let canCenter = initialPlan.origin == nil && initialPlan.stops.isEmpty
            && initialPlan.destination == nil && planner.result == nil
        isLocating = true
        Task { [weak self] in
            guard let self else { return }
            let outcome = await self.locationProvider.requestLocation()
            self.isLocating = false
            self.showsUserLocation = self.locationProvider.isAuthorized
            guard case .success(let coordinate) = outcome else { return }
            let plan = planner.plan
            guard canCenter, self.isMapVisible, self.permitsInitialLocationCamera,
                  !self.hasInteractedWithMap,
                  self.handledRouterFocus == 0, self.nextCommandId == commandId,
                  plan.origin == nil, plan.stops.isEmpty, plan.destination == nil,
                  planner.result == nil, self.selection == nil, self.pendingCoordinate == nil else { return }
            // 服務區之外只顯示藍點，保留台中視角。
            guard let area = self.config?.serviceArea ?? (try? MockFixtures.serviceArea.get()),
                  MockBarHoppingAPI.contains(area, coordinate) else { return }
            self.send(.center(coordinate, zoom: 15))
        }
    }

    enum LocateIntent { case center, setOrigin }
    @ObservationIgnored let locationProvider = LocationProvider()
    private(set) var isLocating = false
    var locationProblem: LocationProvider.Problem?

    func locate(intent: LocateIntent, planner: PlannerStore) {
        guard !isLocating else { return }
        isLocating = true
        locationProblem = nil
        Task { [weak self] in
            guard let self else { return }
            let outcome = await self.locationProvider.requestLocation()
            self.isLocating = false
            switch outcome {
            case .success(let coordinate):
                self.showsUserLocation = true
                self.send(.center(coordinate, zoom: max(self.camera.zoom, 15)))
                if intent == .setOrigin {
                    planner.setOrigin(Waypoint.custom(name: "目前位置", at: coordinate))
                    self.toast = "已將目前位置設為起點"
                }
            case .failure(let problem):
                self.locationProblem = problem
            }
        }
    }

    // MARK: 提示

    var toast: String?
}
