#!/usr/bin/env python3
"""固定種子產生 144 條台中示範熱門步行路線；runCount 並非真實統計。

python3 tools/heat/make_demo_routes.py             # 使用座標雜湊快取
python3 tools/heat/make_demo_routes.py --offline   # 不連網，缺快取即失敗
python3 tools/heat/make_demo_routes.py --refresh   # 明確要求重新查詢
詳細品質、覆蓋範圍與跳過原因寫入 tools/heat/report.json。
"""
import argparse
from collections import Counter
from dataclasses import dataclass
import hashlib
import json
import math
from pathlib import Path
import random
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
BARS = ROOT / "BarHopping/BarHopping/Resources/Data/taichung-bars.json"
OUT = BARS.with_name("taichung-demo-popular-routes.json")
CACHE = Path(__file__).resolve().parent / "raw"
REPORT = CACHE.parent / "report.json"
ENDPOINT = "https://routing.openstreetmap.de/routed-foot/route/v1/foot/"
USER_AGENT = "BarHopping-dev/0.1 (student project)"
MIN_INTERVAL = 1.5
SEED = 20261107
# 名額依主要覆蓋區分組，不是行政界線裁切；跨區路線只在起點組計一次。
QUOTAS = {"西區": 24, "中區": 12, "北區": 18, "南區": 14,
          "東區": 14, "西屯區": 24, "南屯區": 18, "北屯區": 20}
# 開發用人工選定的地標附近概略座標，不是入口、店家或精確地理編碼。
# 熱度也是人工設定的示範區間。
LANDMARKS = {
    "西區": [
        ("審計新村周邊", 24.1446, 120.6620, 150, 250),
        ("勤美草悟道周邊", 24.1517, 120.6633, 150, 250),
        ("市民廣場周邊", 24.1500, 120.6637, 130, 230),
        ("國立臺灣美術館周邊", 24.1410, 120.6639, 75, 145),
        ("科博館南側周邊", 24.1565, 120.6653, 95, 185),
        ("精明一街周邊", 24.1558, 120.6554, 90, 180),
        ("柳川民權路周邊", 24.1398, 120.6730, 40, 95)],
    "中區": [
        ("台中車站舊站周邊", 24.1370, 120.6850, 55, 115),
        ("第二市場周邊", 24.1421, 120.6808, 60, 130),
        ("柳川中華路周邊", 24.1447, 120.6772, 55, 120),
        ("台中公園南側周邊", 24.1441, 120.6847, 65, 135)],
    "北區": [
        ("一中街周邊", 24.1496, 120.6850, 130, 230),
        ("中友百貨周邊", 24.1520, 120.6845, 120, 220),
        ("孔廟周邊", 24.1538, 120.6894, 65, 135),
        ("英才公園周邊", 24.1594, 120.6757, 40, 95),
        ("中國醫藥大學學士路周邊", 24.1572, 120.6816, 60, 130),
        ("北區運動中心周邊", 24.1608, 120.6874, 40, 90),
        ("天津路商圈周邊", 24.1696, 120.6775, 35, 85)],
    "南區": [
        ("國立公共資訊圖書館周邊", 24.1271, 120.6709, 25, 70),
        ("中興大學正門周邊", 24.1236, 120.6750, 35, 85),
        ("忠孝夜市周邊", 24.1301, 120.6840, 50, 110),
        ("健康公園周邊", 24.1194, 120.6660, 15, 55),
        ("大慶車站周邊", 24.1190, 120.6479, 10, 45),
        ("五權車站周邊", 24.1286, 120.6662, 25, 65)],
    "東區": [
        ("台中車站東側周邊", 24.1362, 120.6876, 45, 100),
        ("帝國製糖廠周邊", 24.1402, 120.6974, 30, 80),
        ("樂成宮周邊", 24.1408, 120.6977, 25, 70),
        ("旱溪東英路周邊", 24.1430, 120.7041, 10, 50),
        ("東峰公園東側街區", 24.1239, 120.6927, 10, 50),
        ("建成路振興路周邊", 24.1318, 120.6920, 15, 55)],
    "西屯區": [
        ("逢甲大學正門周邊", 24.1797, 120.6469, 140, 240),
        ("逢甲福星路周邊", 24.1772, 120.6448, 140, 240),
        ("秋紅谷周邊", 24.1678, 120.6399, 110, 200),
        ("台中市政府周邊", 24.1618, 120.6469, 100, 200),
        ("國家歌劇院周邊", 24.1628, 120.6403, 130, 220),
        ("中央公園南側周邊", 24.1850, 120.6550, 25, 75),
        ("水湳經貿路周邊", 24.1915, 120.6592, 15, 55),
        ("東海大學台灣大道周邊", 24.1806, 120.6044, 10, 50),
        ("東海榮總周邊", 24.1830, 120.6145, 10, 45)],
    "南屯區": [
        ("文心森林公園周邊", 24.1450, 120.6469, 55, 125),
        ("豐樂雕塑公園周邊", 24.1328, 120.6444, 25, 70),
        ("萬和宮周邊", 24.1380, 120.6381, 25, 70),
        ("黎明新村周邊", 24.1530, 120.6271, 15, 55),
        ("公益路黎明路周邊", 24.1510, 120.6335, 50, 110),
        ("南屯捷運站周邊", 24.1406, 120.6468, 30, 80),
        ("南苑公園周邊", 24.1266, 120.6521, 10, 45)],
    "北屯區": [
        ("民俗公園周邊", 24.1768, 120.6851, 25, 75),
        ("四維國小捷運站周邊", 24.1717, 120.6930, 25, 70),
        ("崇德文心路周邊", 24.1727, 120.6858, 35, 85),
        ("松竹車站周邊", 24.1804, 120.7012, 15, 60),
        ("舊社公園周邊", 24.1829, 120.6990, 15, 55),
        ("北屯兒童公園周邊", 24.1669, 120.6953, 25, 70),
        ("洲際棒球場周邊", 24.1992, 120.6845, 5, 40),
        ("太原車站周邊", 24.1659, 120.6991, 15, 55),
        ("廍子公園西北側街區", 24.1722, 120.7243, 5, 35)]
}


@dataclass(frozen=True)
class Point:
    id: str
    name: str
    lat: float
    lon: float
    district: str
    low: int
    high: int
    place_id: str | None = None


def meters(a, b):
    """市區尺度的等距圓柱投影距離。"""
    return math.hypot((a.lat - b.lat) * 111_320,
                      (a.lon - b.lon) * 111_320 * math.cos(math.radians((a.lat + b.lat) / 2)))


def points():
    landmarks = [Point(f"landmark-{district}-{i}", name, lat, lon, district, low, high)
                 for district, rows in LANDMARKS.items()
                 for i, (name, lat, lon, low, high) in enumerate(rows)]
    result = list(landmarks)
    # 遠離本次市區地標的酒吧不納入，避免清水／沙鹿等跨城長距離。
    for bar in sorted(json.loads(BARS.read_text()), key=lambda b: b["id"]):
        coordinate = bar["coordinate"]
        p = Point(bar["id"], bar["name"], coordinate["latitude"],
                  coordinate["longitude"], "", 0, 0, bar["id"])
        nearest = min(landmarks, key=lambda landmark: meters(p, landmark))
        if meters(p, nearest) <= 2_500:
            result.append(Point(p.id, p.name, p.lat, p.lon, nearest.district,
                                nearest.low, nearest.high, p.place_id))
    return result


def candidates(all_points):
    rng = random.Random(SEED)
    groups = {}
    used = set()
    for district in QUOTAS:
        pool = [(a, b) for a in all_points if a.district == district
                for b in all_points if a.id != b.id and 850 <= meters(a, b) <= 3_300]
        rng.shuffle(pool)
        # 優先讓每個地標／酒吧出現，再逐漸疊加熱門區；穩定排序保留種子亂數的平手次序。
        visits = Counter()
        ordered = []
        while pool:
            index = min(range(len(pool)), key=lambda i: visits[pool[i][0].id] + visits[pool[i][1].id])
            a, b = pool.pop(index)
            key = tuple(sorted(((round(a.lat, 7), round(a.lon, 7)),
                                (round(b.lat, 7), round(b.lon, 7)))))
            if key in used:
                continue
            used.add(key)
            visits[a.id] += 1
            visits[b.id] += 1
            runs = rng.randint(a.low, a.high)
            ordered.append((a, b, runs))
        groups[district] = ordered
    return groups


def request_key(stops):
    path = ";".join(f"{p.lon:.7f},{p.lat:.7f}" for p in stops)
    url = f"{ENDPOINT}{path}?overview=full&geometries=geojson&steps=false"
    return hashlib.sha256(url.encode()).hexdigest()[:20], url


class Router:
    def __init__(self, refresh=False, offline=False):
        self.refresh = refresh
        self.offline = offline
        self.last_request = 0.0
        self.requests = 0

    def fetch(self, stops):
        key, url = request_key(stops)
        cache = CACHE / f"foot-{key}.json"
        if cache.exists() and not self.refresh:
            return json.loads(cache.read_text())
        if self.offline:
            raise FileNotFoundError(f"缺少快取 {cache.name}")
        for attempt in range(3):
            time.sleep(max(0, MIN_INTERVAL - (time.monotonic() - self.last_request)))
            self.last_request = time.monotonic()
            self.requests += 1
            try:
                request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = json.load(response)
                cache.parent.mkdir(parents=True, exist_ok=True)
                cache.write_text(json.dumps(data, separators=(",", ":")) + "\n")
                return data  # NoRoute 等回應也快取；由品質檢查記錄跳過原因。
            except (OSError, ValueError) as error:
                if attempt == 2:
                    raise RuntimeError(f"三次請求失敗：{error}") from error
                retry_after = error.headers.get("Retry-After", "0") if isinstance(error, urllib.error.HTTPError) else "0"
                delay = max((10, 30)[attempt], float(retry_after) if retry_after.isdigit() else 0)
                time.sleep(delay)
        raise AssertionError("unreachable")


def validated_route(data, stops):
    if data.get("code") != "Ok" or not data.get("routes"):
        raise ValueError(f"路由回應 {data.get('code')}: {data.get('message', '')}")
    route = data["routes"][0]
    distance = route["distance"]
    if not 1_000 <= distance <= 5_000:
        raise ValueError(f"實際步行距離 {distance:.0f} m 不在 1–5 km")
    if distance > meters(*stops) * 2.4:
        raise ValueError(f"繞行比 {distance / meters(*stops):.2f} 超過 2.4")
    waypoints = data.get("waypoints", [])
    if len(waypoints) != len(stops) or any(w.get("distance", math.inf) > 100 for w in waypoints):
        raise ValueError("端點吸附距離超過 100 m 或缺少吸附資訊")
    path = []
    # 保留道路頂點，只量化至 5 位小數並移除連續重複點。
    # 逐路線 Douglas–Peucker 會產生不同弦段，降低既有熱力圖的同邊合併率。
    for lon, lat in route["geometry"]["coordinates"]:
        if not (math.isfinite(lat) and math.isfinite(lon) and -90 <= lat <= 90 and -180 <= lon <= 180):
            raise ValueError("無效路徑座標")
        point = {"latitude": round(lat, 5), "longitude": round(lon, 5)}
        if not path or point != path[-1]:
            path.append(point)
    if len(path) < 2:
        raise ValueError("路徑少於兩個不同座標")
    return distance, path


def generate(refresh=False, offline=False):
    router = Router(refresh, offline)
    groups = candidates(points())
    routes, skipped, distribution, lengths = [], [], Counter(), Counter()
    accepted = []
    for district, quota in QUOTAS.items():
        for a, b, runs in groups[district]:
            if distribution[district] == quota:
                break
            key, _ = request_key((a, b))
            try:
                data = router.fetch((a, b))
                distance, path = validated_route(data, (a, b))
            except FileNotFoundError:
                raise  # 離線檢查不可靜默改選另一條，否則掩蓋快取缺失。
            except (RuntimeError, ValueError, KeyError, TypeError) as error:
                skipped.append({"district": district, "from": a.name, "to": b.name,
                                "cacheKey": key, "reason": str(error)})
                print(f"跳過 {a.name} → {b.name}：{error}", flush=True)
                continue
            route_id = f"demo-route-{key}"
            routes.append({"id": route_id, "title": f"{district}・{a.name}至{b.name}",
                           "runCount": runs, "distanceMeters": round(distance),
                           "stopPlaceIds": [p.place_id or p.id for p in (a, b)],
                           "stopNames": [a.name, b.name], "path": path})
            accepted.append({"id": route_id, "district": district,
                             "kind": "bar-to-bar" if a.place_id and b.place_id else "landmark-walk"})
            distribution[district] += 1
            lengths[district] += round(distance)
            print(f"{len(routes):03d}/144 {district} {a.name} → {b.name}: {distance:.0f} m, {len(path)} 點, {runs} 人", flush=True)
        if distribution[district] != quota:
            raise RuntimeError(f"{district} 候選不足，{distribution[district]}/{quota}；保留原有輸出")
    payload = json.dumps(routes, ensure_ascii=False, separators=(",", ":")) + "\n"
    if len(payload.encode()) >= 1_500_000:
        raise RuntimeError("輸出超過 1.5 MB；保留原有資料")
    temporary_output = OUT.with_suffix(".json.tmp")
    temporary_output.write_text(payload)
    temporary_output.replace(OUT)
    report = {"seed": SEED, "routeCount": len(routes), "districtCounts": dict(distribution),
              "districtDistanceMeters": dict(lengths), "distanceMeters": sum(lengths.values()),
              "bytes": len(payload.encode()), "kinds": dict(Counter(r["kind"] for r in accepted)),
              "skippedCount": len(skipped), "skipped": skipped, "routes": accepted}
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    print(f"已寫入 {len(routes)} 條，{report['bytes']} bytes，本次網路請求 {router.requests} 次", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    flags = parser.add_mutually_exclusive_group()
    flags.add_argument("--refresh", action="store_true")
    flags.add_argument("--offline", action="store_true")
    args = parser.parse_args()
    generate(args.refresh, args.offline)


if __name__ == "__main__":
    main()
