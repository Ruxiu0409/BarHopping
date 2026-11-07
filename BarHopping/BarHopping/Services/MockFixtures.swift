import Foundation

/// Mock 用的固定資料：台中市服務範圍與 28 間虛構酒吧。
/// 店名、地址門牌與 OSM ID 皆為虛構（sourceId 以 9000000xx 開頭，明顯不是真實元素）。
/// 座標大致落在真實街道附近，供地圖顯示與路線示範使用。
nonisolated enum MockFixtures {
    static let placeDataUpdatedAt = date("2026-10-01T00:00:00Z")
    static let routingDataUpdatedAt = date("2026-10-01T00:00:00Z")

    /// 地圖初始視角建議的中心（台中市西區／勤美一帶）。
    static let cityCenter = Coordinate(latitude: 24.1500, longitude: 120.6620)

    /// 台中市區概略邊界（GeoJSON Polygon，[longitude, latitude]，首尾相同），
    /// 涵蓋中、東、西、南、北、西屯、南屯、北屯區。
    static let serviceArea = GeoJSONPolygon(coordinates: [[
        [120.595, 24.120], [120.598, 24.200], [120.630, 24.215], [120.680, 24.245],
        [120.740, 24.235], [120.760, 24.190], [120.730, 24.140], [120.715, 24.105],
        [120.670, 24.095], [120.620, 24.100], [120.595, 24.120],
    ]])

    static let places: [Place] = [
        // 西區：草悟道／勤美
        p(1, "琥珀燈籠 Amber Lantern", .bar, 24.1512, 120.6638, "台中市西區公益路 70 號旁巷內", "Mo-Su 19:00-02:00"),
        p(2, "草悟夜航 Night Ferry", .bar, 24.1497, 120.6643, nil, "Mo-Sa 18:00-24:00"),
        p(3, "綠園道老橡木 Old Oak Pub", .pub, 24.1528, 120.6632, "台中市西區英才路 5 巷 9 號", nil),
        p(4, "勤美紙飛機 Paper Plane Lounge", .bar, 24.1519, 120.6618, "台中市西區館前路 21 號 2 樓", "Mo-Su 18:00-02:00"),
        // 西區：審計新村一帶
        p(5, "審計小酒窖 Audit Cellar", .bar, 24.1447, 120.6624, "台中市西區民生路 368 巷 6 弄 3 號", "Tu-Su 20:00-01:00"),
        p(6, "日式宿舍貓頭鷹 Alley Owl", .pub, 24.1442, 120.6611, nil, nil, kind: "way"),
        p(7, "向上路微醺所 Upward Tipple", .bar, 24.1455, 120.6598, "台中市西區向上路一段 23 號", "Mo-Su 18:00-01:00"),
        // 北區：一中街
        p(8, "一中慢拍 Slow Beat Bar", .bar, 24.1497, 120.6852, "台中市北區一中街 101 巷 5 號", "We-Su 19:00-01:00"),
        p(9, "巷弄十三號 Lane Thirteen", .bar, 24.1489, 120.6866, nil, "Mo-Su 21:00-04:00"),
        p(10, "育才黑麥 Rye & Revival", .pub, 24.1506, 120.6840, "台中市北區育才街 7 號", nil),
        p(11, "三民路藍調燭台 Blue Candle", .bar, 24.1478, 120.6838, "台中市北區三民路三段 88 巷 2 號", "Tu-Su 19:30-01:30"),
        // 中區舊城
        p(12, "紅磚劇場 Red Brick Stage", .bar, 24.1430, 120.6795, "台中市中區繼光街 60 號 2 樓", "Mo-Su 18:00-01:00"),
        p(13, "綠川醉鴿 Tipsy Pigeon", .pub, 24.1385, 120.6838, "台中市中區中山路 12 號", "Mo-Su 17:00-24:00"),
        p(14, "成功路漂流 Drift on Chenggong", .bar, 24.1412, 120.6810, nil, "Fr-Su 20:00-03:00"),
        p(15, "舊城電影吧 Old Town Cinema Bar", .pub, 24.1398, 120.6782, "台中市中區民族路 45 號", nil, kind: "way"),
        // 西屯：逢甲
        p(16, "霓虹溫室 Neon Greenhouse", .bar, 24.1790, 120.6463, "台中市西屯區文華路 120 巷 3 號", "Mo-Su 20:00-03:00"),
        p(17, "逢甲浮島 Floating Isle", .bar, 24.1778, 120.6445, nil, nil),
        p(18, "福星地下室 Basement Session", .pub, 24.1805, 120.6478, "台中市西屯區福星路 450 號 B1", "Mo-Su 20:00-02:00"),
        p(19, "西屯街燈 Streetlamp Tap", .pub, 24.1770, 120.6482, "台中市西屯區西屯路二段 270 巷 8 號", "Th-Su 19:00-01:00"),
        // 西屯：七期／市政路
        p(20, "市政高空座 Skyline Perch", .bar, 24.1572, 120.6442, "台中市西屯區市政路 386 號 18 樓", "Mo-Su 17:00-01:00"),
        p(21, "惠中玻璃森林 Glass Forest", .bar, 24.1590, 120.6468, "台中市西屯區惠中路一段 72 號", nil),
        p(22, "七期月台 Platform Seven", .bar, 24.1558, 120.6405, nil, "Mo-Sa 20:00-02:00"),
        p(23, "大墩街角 Corner Tap", .pub, 24.1545, 120.6488, "台中市西屯區大墩十九街 30 號", "Tu-Su 18:00-24:00", kind: "way"),
        // 西屯：精明一街
        p(24, "精明靜巷 Quiet Lane", .bar, 24.1534, 120.6562, "台中市西屯區精明一街 66 號", "Mo-Su 19:00-01:00"),
        p(25, "精誠小酌 Jingcheng Sip", .bar, 24.1528, 120.6575, nil, nil),
        // 南屯：公益路
        p(26, "公益路雙城 Twin Cities Tap", .pub, 24.1517, 120.6478, "台中市南屯區公益路二段 102 號", "Mo-Su 17:00-01:00"),
        p(27, "黎明夜燈 Dawnlight Bar", .bar, 24.1510, 120.6428, "台中市南屯區公益路二段 316 號", nil),
        p(28, "公益慢燉 Slow Brew House", .pub, 24.1522, 120.6520, nil, "We-Mo 18:00-24:00"),
    ]

    private static func p(_ n: Int, _ name: String, _ category: PlaceCategory, _ lat: Double, _ lon: Double,
                          _ address: String?, _ hours: String?, kind: String = "node") -> Place {
        Place(id: String(format: "mock-%04d", n), name: name,
              coordinate: Coordinate(latitude: lat, longitude: lon), category: category,
              address: address, openingHoursText: hours, source: "osm",
              sourceId: "\(kind)/\(900_000_000 + n)", updatedAt: placeDataUpdatedAt)
    }

    private static func date(_ iso: String) -> Date {
        JSONCoding.parseISO8601(iso) ?? Date(timeIntervalSince1970: 0)
    }
}
