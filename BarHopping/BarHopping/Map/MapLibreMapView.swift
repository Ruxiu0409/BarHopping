import CoreLocation
import MapLibre
import SwiftUI
import UIKit

/// 地圖上要畫的內容（只用共用型別；MapLibre 型別只留在這個檔案）。
struct MapRenderModel: Equatable {
    struct PlacePin: Equatable {
        enum State: String { case normal, selected, inRoute }
        var id: String
        var name: String
        var coordinate: Coordinate
        var state: State
    }

    struct WaypointPin: Equatable {
        enum Kind: String { case origin, destination, stop, problem, pending }
        var id: String
        var coordinate: Coordinate
        var label: String
        var kind: Kind
        var selected: Bool
    }

    var convenienceStores: [ConvenienceStore] = []
    var places: [PlacePin] = []
    var waypoints: [WaypointPin] = []
    var legs: [[Coordinate]] = []
    var routeFaded = false
    var snappedPoints: [Coordinate] = []
}

/// MLNMapView 的 SwiftUI 包裝。
struct MapLibreMapView: UIViewRepresentable {
    var state: MapScreenState
    var model: MapRenderModel
    var styleURL: URL
    var styleReloadToken: Int
    var cameraCommand: MapScreenState.CameraCommand?
    var showsUserLocation: Bool

    func makeCoordinator() -> Coordinator { Coordinator(state: state) }

    func makeUIView(context: Context) -> MLNMapView {
        let map = MLNMapView(frame: .zero, styleURL: styleURL)
        let c = context.coordinator
        c.mapView = map
        c.styleURL = styleURL
        c.reloadToken = styleReloadToken
        map.overrideUserInterfaceStyle = .dark
        map.backgroundColor = MapTheme.uiHalo
        map.tintColor = MapTheme.uiLabel
        map.delegate = c
        map.automaticallyAdjustsContentInset = false
        map.isRotateEnabled = false
        map.isPitchEnabled = false
        map.compassView.isHidden = true
        map.logoView.isHidden = true
        map.attributionButton.isHidden = true   // 改用 SwiftUI 的可點擊標示列
        map.setCenter(state.camera.center.cl, zoomLevel: state.camera.zoom, animated: false)
        // 已處理過的指令不重播（例如重新建立地圖時）
        c.handledCommandId = cameraCommand?.id ?? 0

        let tap = UITapGestureRecognizer(target: c, action: #selector(Coordinator.handleTap(_:)))
        for r in map.gestureRecognizers ?? [] {
            if let t = r as? UITapGestureRecognizer, t.numberOfTapsRequired == 2 { tap.require(toFail: t) }
        }
        map.addGestureRecognizer(tap)
        let press = UILongPressGestureRecognizer(target: c, action: #selector(Coordinator.handleLongPress(_:)))
        press.delegate = c
        map.addGestureRecognizer(press)
        return map
    }

    func updateUIView(_ map: MLNMapView, context: Context) {
        let c = context.coordinator
        c.state = state
        if c.styleURL != styleURL {
            c.styleURL = styleURL
            c.styleLoaded = false
            map.styleURL = styleURL
        } else if c.reloadToken != styleReloadToken {
            c.reloadToken = styleReloadToken
            c.styleLoaded = false
            map.styleURL = styleURL
            map.reloadStyle(nil)
        }
        if map.showsUserLocation != showsUserLocation { map.showsUserLocation = showsUserLocation }
        c.render(model)
        if let cameraCommand, cameraCommand.id != c.handledCommandId {
            c.pendingCommand = cameraCommand
        }
        c.applyPendingCommand()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var state: MapScreenState
        weak var mapView: MLNMapView?
        var styleURL: URL?
        var reloadToken = 0
        var styleLoaded = false
        var handledCommandId = 0
        var pendingCommand: MapScreenState.CameraCommand?
        private var lastModel: MapRenderModel?
        private var model = MapRenderModel()

        private var convenienceSource: MLNShapeSource?
        private var placeSource: MLNShapeSource?
        private var waypointSource: MLNShapeSource?
        private var routeSource: MLNShapeSource?
        private var snappedSource: MLNShapeSource?
        private var routeLayer: MLNLineStyleLayer?
        private var routeCasing: MLNLineStyleLayer?

        static let convenienceLayerId = "bh-convenience-circle"
        static let placeLayerId = "bh-places-circle"
        static let waypointLayerId = "bh-waypoints-circle"

        init(state: MapScreenState) { self.state = state }

        // MARK: Style 與資料

        func styleDidLoad(_ style: MLNStyle) {
            let convenienceSource = MLNShapeSource(identifier: "bh-convenience", shape: nil)
            let routeSource = MLNShapeSource(identifier: "bh-route", shape: nil)
            let snappedSource = MLNShapeSource(identifier: "bh-snapped", shape: nil)
            let placeSource = MLNShapeSource(identifier: "bh-places", shape: nil)
            let waypointSource = MLNShapeSource(identifier: "bh-waypoints", shape: nil)
            [convenienceSource, routeSource, snappedSource, placeSource, waypointSource].forEach { style.addSource($0) }

            // 超商在路線、酒吧與站點下面，並以 style 的縮放門檻避免縮小時顯示。
            let store = MLNCircleStyleLayer(identifier: Self.convenienceLayerId, source: convenienceSource)
            store.minimumZoomLevel = Float(MapScreenState.convenienceMinimumZoom)
            store.circleRadius = NSExpression(forConstantValue: 6)
            store.circleColor = NSExpression(format: "MLN_MATCH(brand, '7-ELEVEN', %@, %@)",
                                              MapTheme.uiSevenEleven, MapTheme.uiFamilyMart)
            store.circleStrokeColor = NSExpression(forConstantValue: MapTheme.uiLabel.withAlphaComponent(0.6))
            store.circleStrokeWidth = NSExpression(forConstantValue: 0.75)
            style.addLayer(store)

            let storeLabel = MLNSymbolStyleLayer(identifier: "bh-convenience-label", source: convenienceSource)
            storeLabel.minimumZoomLevel = Float(MapScreenState.convenienceMinimumZoom)
            storeLabel.text = NSExpression(forKeyPath: "label")
            storeLabel.textFontNames = NSExpression(forConstantValue: ["Noto Sans Bold"])
            storeLabel.textFontSize = NSExpression(forConstantValue: 9)
            storeLabel.textColor = NSExpression(forConstantValue: UIColor.white)
            storeLabel.textAllowsOverlap = NSExpression(forConstantValue: true)
            storeLabel.textIgnoresPlacement = NSExpression(forConstantValue: true)
            style.addLayer(storeLabel)

            let casing = MLNLineStyleLayer(identifier: "bh-route-casing", source: routeSource)
            casing.lineColor = NSExpression(forConstantValue: MapTheme.uiHalo)
            casing.lineWidth = NSExpression(forConstantValue: 9)
            casing.lineJoin = NSExpression(forConstantValue: "round")
            casing.lineCap = NSExpression(forConstantValue: "round")
            style.addLayer(casing)

            let line = MLNLineStyleLayer(identifier: "bh-route-line", source: routeSource)
            line.lineColor = NSExpression(forConstantValue: MapTheme.uiAccent)
            line.lineWidth = NSExpression(forConstantValue: 5)
            line.lineJoin = NSExpression(forConstantValue: "round")
            line.lineCap = NSExpression(forConstantValue: "round")
            style.addLayer(line)

            let snapped = MLNCircleStyleLayer(identifier: "bh-snapped-circle", source: snappedSource)
            snapped.circleRadius = NSExpression(forConstantValue: 3.5)
            snapped.circleColor = NSExpression(forConstantValue: MapTheme.uiLabel)
            snapped.circleStrokeColor = NSExpression(forConstantValue: MapTheme.uiHalo)
            snapped.circleStrokeWidth = NSExpression(forConstantValue: 1.5)
            style.addLayer(snapped)

            let place = MLNCircleStyleLayer(identifier: Self.placeLayerId, source: placeSource)
            place.circleRadius = NSExpression(format: "MLN_MATCH(state, 'selected', 11, 7)")
            place.circleColor = NSExpression(format: "MLN_MATCH(state, 'inRoute', %@, %@)",
                                             UIColor.systemGray, MapTheme.uiAccent)
            place.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
            place.circleStrokeWidth = NSExpression(format: "MLN_MATCH(state, 'selected', 3, 2)")
            style.addLayer(place)

            let placeLabel = MLNSymbolStyleLayer(identifier: "bh-places-label", source: placeSource)
            placeLabel.text = NSExpression(forKeyPath: "name")
            placeLabel.textFontNames = NSExpression(forConstantValue: ["Noto Sans Regular"])
            placeLabel.textFontSize = NSExpression(forConstantValue: 12)
            placeLabel.textColor = NSExpression(forConstantValue: MapTheme.uiLabel)
            placeLabel.textHaloColor = NSExpression(forConstantValue: MapTheme.uiHalo)
            placeLabel.textHaloWidth = NSExpression(forConstantValue: 1.5)
            placeLabel.textAnchor = NSExpression(forConstantValue: "left")
            placeLabel.textOffset = NSExpression(forConstantValue: NSValue(cgVector: CGVector(dx: 0.9, dy: 0)))
            placeLabel.textOptional = NSExpression(forConstantValue: true)
            placeLabel.minimumZoomLevel = 14.5
            style.addLayer(placeLabel)

            let wp = MLNCircleStyleLayer(identifier: Self.waypointLayerId, source: waypointSource)
            wp.circleRadius = NSExpression(format: "MLN_MATCH(kind, 'pending', 8, 12)")
            wp.circleColor = NSExpression(
                format: "MLN_MATCH(kind, 'origin', %@, 'destination', %@, 'problem', %@, 'pending', %@, %@)",
                MapTheme.uiOrigin, MapTheme.uiDestination, UIColor.systemRed, UIColor.systemGray, MapTheme.uiAccent)
            wp.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)
            wp.circleStrokeWidth = NSExpression(format: "TERNARY(selected == YES, 4, 2.5)")
            style.addLayer(wp)

            let wpLabel = MLNSymbolStyleLayer(identifier: "bh-waypoints-label", source: waypointSource)
            wpLabel.text = NSExpression(forKeyPath: "label")
            wpLabel.textFontNames = NSExpression(forConstantValue: ["Noto Sans Bold"])
            wpLabel.textFontSize = NSExpression(forConstantValue: 12)
            wpLabel.textColor = NSExpression(forConstantValue: UIColor.white)
            wpLabel.textHaloColor = NSExpression(forConstantValue: MapTheme.uiHalo)
            wpLabel.textHaloWidth = NSExpression(forConstantValue: 1)
            wpLabel.textAllowsOverlap = NSExpression(forConstantValue: true)
            wpLabel.textIgnoresPlacement = NSExpression(forConstantValue: true)
            style.addLayer(wpLabel)

            self.convenienceSource = convenienceSource
            self.routeSource = routeSource
            self.snappedSource = snappedSource
            self.placeSource = placeSource
            self.waypointSource = waypointSource
            self.routeLayer = line
            self.routeCasing = casing
            styleLoaded = true
            lastModel = nil
            render(model)
        }

        func render(_ newModel: MapRenderModel) {
            model = newModel
            guard styleLoaded, newModel != lastModel else { return }
            let old = lastModel
            lastModel = newModel

            if old?.convenienceStores != newModel.convenienceStores {
                convenienceSource?.shape = MLNShapeCollectionFeature(shapes: newModel.convenienceStores.map { store in
                    let feature = MLNPointFeature()
                    feature.coordinate = store.coordinate.cl
                    feature.attributes = ["storeId": store.id, "brand": store.brand.rawValue,
                                          "label": store.brand == .sevenEleven ? "7" : "全"]
                    return feature
                })
            }
            if old?.places != newModel.places {
                placeSource?.shape = MLNShapeCollectionFeature(shapes: newModel.places.map { p in
                    let f = MLNPointFeature()
                    f.coordinate = p.coordinate.cl
                    f.attributes = ["placeId": p.id, "name": p.name, "state": p.state.rawValue]
                    return f
                })
            }
            if old?.waypoints != newModel.waypoints {
                // 編號站點畫在最上層：反向加入讓起點與第一站在上方
                waypointSource?.shape = MLNShapeCollectionFeature(shapes: newModel.waypoints.reversed().map { w in
                    let f = MLNPointFeature()
                    f.coordinate = w.coordinate.cl
                    f.attributes = ["waypointId": w.id, "label": w.label, "kind": w.kind.rawValue, "selected": w.selected]
                    return f
                })
            }
            if old?.legs != newModel.legs {
                routeSource?.shape = MLNShapeCollectionFeature(shapes: newModel.legs.filter { $0.count >= 2 }.map { leg in
                    let coords = leg.map(\.cl)
                    return MLNPolylineFeature(coordinates: coords, count: UInt(coords.count))
                })
            }
            if old?.snappedPoints != newModel.snappedPoints {
                snappedSource?.shape = MLNShapeCollectionFeature(shapes: newModel.snappedPoints.map { c in
                    let f = MLNPointFeature()
                    f.coordinate = c.cl
                    return f
                })
            }
            if old?.routeFaded != newModel.routeFaded {
                let faded = newModel.routeFaded
                routeLayer?.lineOpacity = NSExpression(forConstantValue: faded ? 0.6 : 1)
                routeCasing?.lineOpacity = NSExpression(forConstantValue: faded ? 0.6 : 1)
                routeLayer?.lineDashPattern = faded ? NSExpression(forConstantValue: [1.5, 1.2]) : nil
                routeLayer?.lineColor = NSExpression(forConstantValue: MapTheme.uiAccent)
            }
        }

        // MARK: 鏡頭

        func applyPendingCommand() {
            guard let map = mapView, let command = pendingCommand, map.bounds.width > 0, map.bounds.height > 0 else { return }
            pendingCommand = nil
            handledCommandId = command.id
            switch command.kind {
            case .center(let c, let zoom):
                if let zoom {
                    map.setCenter(c.cl, zoomLevel: zoom, animated: true)
                } else {
                    map.setCenter(c.cl, animated: true)
                }
            case .fit(let coords):
                guard let first = coords.first else { return }
                var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
                for c in coords {
                    minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
                    minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
                }
                if maxLat - minLat < 0.0005 && maxLon - minLon < 0.0005 {
                    map.setCenter(first.cl, zoomLevel: max(map.zoomLevel, 15), animated: true)
                    return
                }
                let i = state.overlayInsets
                let h = map.bounds.height, w = map.bounds.width
                // 避開浮動元件，但保留至少三分之一的可見高度
                let top = min(i.top + 24, h * 0.35), bottom = min(i.bottom + 24, h * 0.4)
                let side = min(36, w * 0.1)
                let bounds = MLNCoordinateBounds(sw: CLLocationCoordinate2D(latitude: minLat, longitude: minLon),
                                                 ne: CLLocationCoordinate2D(latitude: maxLat, longitude: maxLon))
                map.setVisibleCoordinateBounds(bounds, edgePadding: UIEdgeInsets(top: top, left: side, bottom: bottom, right: side),
                                               animated: true, completionHandler: nil)
            }
        }

        // MARK: 手勢

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let map = mapView, gesture.state == .ended else { return }
            let p = gesture.location(in: map)
            let rect = CGRect(x: p.x - 22, y: p.y - 22, width: 44, height: 44)
            let wps = map.visibleFeatures(in: rect, styleLayerIdentifiers: [Self.waypointLayerId])
            if let id = nearest(wps, to: p, in: map)?.attribute(forKey: "waypointId") as? String {
                state.selection = .waypoint(id)
                state.listExpanded = false
                return
            }
            let places = map.visibleFeatures(in: rect, styleLayerIdentifiers: [Self.placeLayerId])
            if let id = nearest(places, to: p, in: map)?.attribute(forKey: "placeId") as? String,
               let place = state.places.first(where: { $0.id == id }) {
                state.select(place, moveCamera: false)
                return
            }
            let stores = map.visibleFeatures(in: rect, styleLayerIdentifiers: [Self.convenienceLayerId])
            if let id = nearest(stores, to: p, in: map)?.attribute(forKey: "storeId") as? String,
               let store = state.convenienceStores.first(where: { $0.id == id }) {
                state.selection = .convenienceStore(store)
                state.pendingCoordinate = nil
                state.listExpanded = false
                return
            }
            state.selection = nil
            state.pendingCoordinate = nil
        }

        private func nearest(_ features: [any MLNFeature], to p: CGPoint, in map: MLNMapView) -> (any MLNFeature)? {
            features.min { a, b in
                let pa = map.convert(a.coordinate, toPointTo: map), pb = map.convert(b.coordinate, toPointTo: map)
                return hypot(pa.x - p.x, pa.y - p.y) < hypot(pb.x - p.x, pb.y - p.y)
            }
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let map = mapView, gesture.state == .began else { return }
            let c = map.convert(gesture.location(in: map), toCoordinateFrom: map)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            state.pendingCoordinate = Coordinate(latitude: c.latitude, longitude: c.longitude)
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}

extension MapLibreMapView.Coordinator: @preconcurrency MLNMapViewDelegate {
    func mapView(_ mapView: MLNMapView, didFinishLoading style: MLNStyle) {
        state.mapLoadError = nil
        styleDidLoad(style)
        applyPendingCommand()
    }

    func mapViewDidFailLoadingMap(_ mapView: MLNMapView, withError error: any Error) {
        state.mapLoadError = "底圖載入失敗，仍可繼續編輯路線。"
    }

    func mapView(_ mapView: MLNMapView, regionWillChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        state.cancelConvenienceQuery()
    }

    func mapView(_ mapView: MLNMapView, regionDidChangeWith reason: MLNCameraChangeReason, animated: Bool) {
        let center = mapView.centerCoordinate
        state.camera = .init(center: Coordinate(latitude: center.latitude, longitude: center.longitude), zoom: mapView.zoomLevel)
        let b = mapView.visibleCoordinateBounds
        state.visibleBounds = BoundingBox(west: b.sw.longitude, south: b.sw.latitude, east: b.ne.longitude, north: b.ne.latitude)
        state.refreshConvenienceStores()
        let gestures: MLNCameraChangeReason = [.gesturePan, .gesturePinch, .gestureZoomIn, .gestureZoomOut, .gestureOneFingerZoom]
        if !reason.intersection(gestures).isEmpty, !state.userMovedMap {
            state.userMovedMap = true
        }
    }
}

extension Coordinate {
    fileprivate var cl: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: latitude, longitude: longitude) }
}
