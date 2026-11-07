import MapKit
import SwiftUI

struct FreeRunMapView: View {
    let session: FreeRunSession
    let friends: [FriendLocation]
    let now: Date
    var isSummary = false
    var heatSegments: [PopularRouteSegment] = []
    var heading: Double?
    var attributions: [String] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appReduceMotion) private var appReduceMotion
    @State private var camera: MapCameraPosition = .automatic
    @State private var followsUser = true
    @State private var showsFriends = true
    @State private var showsHeatmap = true
    @State private var showsBars = true
    @State private var tilted = false
    @State private var showsLayers = false
    @State private var showsAttribution = false
    @State private var lastCamera: MapCamera?
    @State private var selectedFriendID: Int?
    @State private var showsFriendDetail = false

    var body: some View {
        Map(position: $camera, interactionModes: isSummary ? [] : .all) {
            if !isSummary, showsHeatmap {
                ForEach(Array(heatSegments.enumerated()), id: \.offset) { _, segment in
                    MapPolyline(coordinates: segment.path.map(\.mapCoordinate))
                        .stroke(FreeRunHeatStyle.color(segment.heat).opacity(0.12 + segment.heat * 0.28),
                                style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                    MapPolyline(coordinates: segment.path.map(\.mapCoordinate))
                        .stroke(FreeRunHeatStyle.color(segment.heat).opacity(0.35 + segment.heat * 0.6),
                                style: StrokeStyle(lineWidth: 3 + segment.heat * 3, lineCap: .round, lineJoin: .round))
                }
            }
            if !isSummary, let user = session.currentCoordinate, let target = session.activeBar {
                MapPolyline(coordinates: [user.mapCoordinate, target.place.coordinate.mapCoordinate])
                    .stroke(AppTheme.accentOnDark.opacity(0.65), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
            }
            ForEach(Array(session.trackSegments.enumerated()), id: \.offset) { _, segment in
                if segment.count > 1 {
                    MapPolyline(coordinates: segment.map(\.mapCoordinate))
                        .stroke(AppTheme.accentOnDark, style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                    MapPolyline(coordinates: segment.map(\.mapCoordinate))
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                }
            }
            ForEach(showsBars && !isSummary ? Array(session.nearby.prefix(12)) : []) { bar in
                Annotation(bar.place.name, coordinate: bar.place.coordinate.mapCoordinate) {
                    barMarker(visited: session.visits.contains { $0.barID == bar.id }, next: !isSummary && bar.id == session.activeBarID)
                }
            }
            if !isSummary, showsBars, let target = session.activeBar, !session.nearby.prefix(12).contains(where: { $0.id == target.id }) {
                Annotation("下一站 · \(target.place.name)", coordinate: target.place.coordinate.mapCoordinate) {
                    barMarker(visited: false, next: true)
                }
            }
            ForEach(showsBars || isSummary ? visitedBars : []) { visit in
                if isSummary || !session.nearby.prefix(12).contains(where: { $0.id == visit.barID }) {
                    Annotation(visit.name, coordinate: visit.coordinate.mapCoordinate) {
                        barMarker(visited: true)
                    }
                }
            }
            if !isSummary, let coordinate = session.currentCoordinate {
                Annotation(session.isDemo ? "我的位置（示範）" : "我的位置", coordinate: coordinate.mapCoordinate) {
                    ZStack {
                        if let heading {
                            FreeRunHeadingCone()
                                .fill(AppTheme.accentOnDark.opacity(0.35))
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(heading - (lastCamera?.heading ?? 0)))
                        }
                        Circle().fill(AppTheme.accent)
                            .frame(width: 22, height: 22)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    }
                }
            }
            if !isSummary, showsFriends {
                ForEach(friends) { friend in
                    Annotation(friend.nickname, coordinate: friend.coordinate.mapCoordinate) {
                        Button {
                            selectedFriendID = friend.id
                            showsFriendDetail = true
                        } label: {
                            Image(systemName: friend.symbol)
                                .font(.body.bold()).foregroundStyle(.black)
                                .frame(width: 44, height: 44)
                                .background(friendColor(friend.id), in: Circle())
                                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(friend.nickname)，模擬位置，查看距離與更新時間")
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .preferredColorScheme(.dark)
        .onMapCameraChange { context in lastCamera = context.camera }
        .animation(AppMotion.resolved(.linear(duration: 1.5), reduceMotion: reduceMotion || appReduceMotion), value: friends)
        .onChange(of: camera.positionedByUser) { _, positionedByUser in
            if positionedByUser { followsUser = false }
        }
        .onChange(of: session.currentCoordinate) { _, _ in
            if followsUser, !isSummary { recenter() }
        }
        .onAppear {
            if isSummary { frameTrack() } else { recenter() }
        }
        .overlay(alignment: .topTrailing) {
            if !isSummary {
                GeometryReader { geometry in
                    let layout = geometry.size.height >= 260
                        ? AnyLayout(VStackLayout(spacing: 10))
                        : AnyLayout(HStackLayout(spacing: 8))
                    layout {
                        Button("指南針，朝北", systemImage: "location.north.fill") { orientNorth() }
                            .rotationEffect(.degrees(-(lastCamera?.heading ?? 0)))
                        Button("圖層", systemImage: "square.3.layers.3d") { showsLayers = true }
                            .overlay(alignment: .topTrailing) {
                                Text("\([showsHeatmap, showsFriends, showsBars].filter { $0 }.count)")
                                    .font(.caption2.bold()).padding(4)
                                    .background(AppTheme.elevated, in: Circle()).offset(x: 4, y: -4)
                            }
                        Button {
                            tilted.toggle()
                            changePitch()
                        } label: {
                            Text("3D").font(.subheadline.bold())
                        }
                        .accessibilityLabel(tilted ? "切換平面地圖" : "切換 3D 地圖")
                        Button("回到我的位置並跟隨", systemImage: followsUser ? "location.fill" : "location") {
                            followsUser = true
                            recenter()
                        }
                        .disabled(session.currentCoordinate == nil)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(FreeRunMapButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(12)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if !isSummary {
                Button("地圖與熱力圖資料來源", systemImage: "info.circle") { showsAttribution = true }
                    .labelStyle(.iconOnly).buttonStyle(FreeRunMapButtonStyle()).padding(12)
            }
        }
        .sheet(isPresented: $showsLayers) {
            Form {
                Toggle("熱門路線（示範熱度）", isOn: $showsHeatmap)
                Toggle("朋友（模擬位置）", isOn: $showsFriends)
                Toggle("酒吧標記", isOn: $showsBars)
                Text("示範：朋友位置為模擬資料").font(.footnote)
                Button("完成") { showsLayers = false }
            }
            .presentationDetents([.medium]).preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showsAttribution) {
            ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("地圖與路線資料").font(.title2.bold())
                Text("底圖由 Apple 地圖提供，授權標示保留於地圖上。")
                Text("內附道路路徑以 OpenStreetMap 資料為基礎，由 FOSSGIS 步行路由產生。酒吧目錄的開放資料來源列於下方。")
                Text("熱門路線與熱度人數為內附示範資料，不代表即時人潮。此畫面不呼叫路由服務；前往下一站的虛線只是方向提示。")
                Link("© OpenStreetMap contributors", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                    .frame(minHeight: 44)
                Link("FOSSGIS 路由資料來源", destination: URL(string: "https://routing.openstreetmap.de/")!)
                    .frame(minHeight: 44)
                ForEach(attributions, id: \.self) { attribution in
                    Text(attribution).font(.caption).textSelection(.enabled)
                }
                Button("關閉") { showsAttribution = false }.frame(minWidth: 44, minHeight: 44)
            }
            .padding(24)
            }
            .presentationDetents([.medium, .large]).preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showsFriendDetail) {
            VStack(alignment: .leading, spacing: 16) {
                if let friend = friends.first(where: { $0.id == selectedFriendID }) {
                    Label(friend.nickname, systemImage: friend.symbol).font(.title2.bold())
                    if let coordinate = session.currentCoordinate {
                        Text("距離你約 \(Int(friend.distance(from: coordinate).rounded())) 公尺")
                    } else {
                        Text("等待你的位置，暫時無法計算距離。")
                    }
                    Text("最後更新 \(friend.age(at: now)) 秒前")
                } else {
                    Text("等待位置更新…")
                }
                Text("示範：朋友位置為模擬資料")
                    .foregroundStyle(AppTheme.accentOnDark)
                Text("正式分享需要雙方同意。本示範不會上傳或分享你的位置。")
                    .font(.footnote).foregroundStyle(AppTheme.textSecondary)
                Button("關閉") { showsFriendDetail = false }.buttonStyle(FreeRunActionButtonStyle())
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .preferredColorScheme(.dark)
        }
    }

    private var visitedBars: [FreeRunVisit] {
        var ids = Set<String>()
        return session.visits.filter { ids.insert($0.barID).inserted }
    }

    private func barMarker(visited: Bool, next: Bool = false) -> some View {
        Image(systemName: visited ? "checkmark" : "wineglass.fill")
            .font(.caption.bold())
            .foregroundStyle(visited ? AppTheme.background : AppTheme.textPrimary)
            .padding(next ? 15 : 9)
            .background(visited ? AppTheme.accentOnDark : AppTheme.accent, in: Circle())
            .overlay(Circle().strokeBorder(next ? AppTheme.accentOnDark : .white.opacity(0.8), lineWidth: next ? 4 : 1))
            .accessibilityLabel(visited ? "已喝過" : (next ? "下一站推薦" : "附近酒吧"))
    }

    private func friendColor(_ id: Int) -> Color {
        switch id {
        case 0: AppTheme.accentOnDark
        case 1: AppTheme.info
        default: .orange
        }
    }

    private func recenter() {
        guard let coordinate = session.currentCoordinate else { return }
        camera = .camera(MapCamera(centerCoordinate: coordinate.mapCoordinate, distance: 800,
                                   heading: lastCamera?.heading ?? 0, pitch: tilted ? 50 : 0))
    }

    private func orientNorth() {
        guard let current = lastCamera else { return }
        camera = .camera(MapCamera(centerCoordinate: current.centerCoordinate, distance: current.distance,
                                   heading: 0, pitch: tilted ? 50 : 0))
    }

    private func changePitch() {
        guard let current = lastCamera else { return }
        camera = .camera(MapCamera(centerCoordinate: current.centerCoordinate, distance: current.distance,
                                   heading: current.heading, pitch: tilted ? 50 : 0))
    }

    private func frameTrack() {
        let points = session.trackSegments.flatMap { $0 } + session.visits.map(\.coordinate)
        guard let first = points.first else { return }
        var rect = MKMapRect(origin: MKMapPoint(first.mapCoordinate), size: MKMapSize(width: 0, height: 0))
        for point in points {
            rect = rect.union(MKMapRect(origin: MKMapPoint(point.mapCoordinate), size: MKMapSize(width: 1, height: 1)))
        }
        let padding = max(150, max(rect.width, rect.height) * 0.2)
        camera = .rect(rect.insetBy(dx: -padding, dy: -padding))
    }
}

private extension Coordinate {
    var mapCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
