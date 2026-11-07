#!/usr/bin/env python3
"""產生熱門路線熱力圖用的 20 條示範路線（假資料）。

站點取自 App 內附的台中酒吧資料，步行路徑向 FOSSGIS 的 OSRM 步行路由
（routing.openstreetmap.de/routed-foot，OSM 資料，ODbL）查詢，讓線條沿著真實街道。
跑過的人數 runCount 是手寫的示範數字，不是真實統計。

從專案根目錄執行：
    python3 tools/heat/make_demo_routes.py           # 優先使用快取
    python3 tools/heat/make_demo_routes.py --refresh # 重新查詢路由
"""
import json
import sys
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BARS = ROOT / "BarHopping/BarHopping/Resources/Data/taichung-bars.json"
OUT = ROOT / "BarHopping/BarHopping/Resources/Data/taichung-demo-popular-routes.json"
CACHE = Path(__file__).resolve().parent / "raw"
ENDPOINT = "https://routing.openstreetmap.de/routed-foot/route/v1/foot/"
USER_AGENT = "BarHopping-dev/0.1 (student project)"
MIN_INTERVAL = 1.5  # 秒；公共服務，請求之間保持間隔

# (標題, 示範跑過人數, 站點 OSM 來源 ID)
ROUTES = [
    ("審計新村短程入門", 203, ["node/10917441173", "node/6313717985", "node/10118954831"]),
    ("審計新村微醺線", 186, ["node/10917441173", "node/6313717985", "node/10118954831", "node/7836694752", "node/4636344790"]),
    ("勤美草悟道經典", 152, ["node/6313717985", "node/7836694752", "node/4636344790", "node/6106605008", "node/6241778567"]),
    ("草悟道回審計", 140, ["node/4636344790", "node/7836694752", "node/10118954831", "node/10917441173"]),
    ("精明一街慢慢喝", 121, ["node/8250740352", "node/6241778567", "node/6106605008", "node/4636344790", "node/10029125584"]),
    ("台中車站老派巡禮", 112, ["node/4655543965", "node/11420318870", "node/11002943806", "node/11898593237"]),
    ("中興街文青線", 96, ["node/13391309091", "node/7125697918", "node/5562871380", "node/11873114870"]),
    ("西區全區精選", 95, ["node/8250740352", "node/6241778567", "node/4636344790", "node/7836694752", "node/10118954831", "node/10917441173", "node/7836854085"]),
    ("公益路餐酒館", 88, ["node/4308829878", "node/10029125584", "way/592647423", "node/6241778567"]),
    ("第二市場精釀", 79, ["node/5031349823", "node/8748627300", "node/11898593237", "node/4339469589"]),
    ("五權西路夜散步", 73, ["node/14088580258", "node/14006235445", "node/10895503569", "node/10917441173"]),
    ("新光遠百週末線", 68, ["node/10914501400", "node/6203243078", "node/6105022592", "node/7256073187"]),
    ("美術館周邊", 64, ["node/5552464437", "node/5645870212", "node/4882704021"]),
    ("一中街北上", 58, ["node/8557945249", "node/7259793135", "node/7259793137", "node/8111898557"]),
    ("向上路小酒館", 57, ["node/7836854085", "node/8862669362", "node/10917441173", "node/6313717985"]),
    ("中區到審計長征", 45, ["node/4339469589", "node/11873114870", "node/7836854085", "node/10917441173", "node/6313717985"]),
    ("草悟道北段", 41, ["node/11287618241", "node/14188593601", "node/13391309091", "node/7125697918"]),
    ("勤美到美術館", 39, ["node/10029125584", "node/5552464437", "node/5645870212", "node/4882704021"]),
    ("七期夜景", 34, ["node/7256073187", "node/13957337896", "node/4423649811"]),
    ("北區居酒屋", 26, ["node/8111898557", "node/5534174346"]),
]


def fetch(coords, cache_file, refresh, last_request):
    if cache_file.exists() and not refresh:
        return json.loads(cache_file.read_text()), last_request
    wait = MIN_INTERVAL - (time.monotonic() - last_request)
    if wait > 0:
        time.sleep(wait)
    path = ";".join(f"{lon},{lat}" for lat, lon in coords)
    url = f"{ENDPOINT}{path}?overview=full&geometries=geojson"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt, backoff in enumerate([0, 10, 30]):
        if backoff:
            time.sleep(backoff)
        try:
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = json.load(resp)
            break
        except Exception as error:  # noqa: BLE001
            if attempt == 2:
                raise SystemExit(f"路由查詢失敗：{error}")
    if data.get("code") != "Ok" or not data.get("routes"):
        raise SystemExit(f"路由回應錯誤：{data.get('code')} {data.get('message')}")
    cache_file.parent.mkdir(parents=True, exist_ok=True)
    cache_file.write_text(json.dumps(data))
    return data, time.monotonic()


def main():
    refresh = "--refresh" in sys.argv
    bars = {b["sourceId"]: b for b in json.loads(BARS.read_text())}
    out, last_request = [], 0.0
    for index, (title, runs, stop_ids) in enumerate(ROUTES, start=1):
        missing = [s for s in stop_ids if s not in bars]
        if missing:
            raise SystemExit(f"{title}：找不到酒吧 {missing}")
        stops = [bars[s] for s in stop_ids]
        coords = [(b["coordinate"]["latitude"], b["coordinate"]["longitude"]) for b in stops]
        route_id = f"demo-route-{index:02d}"
        data, last_request = fetch(coords, CACHE / f"{route_id}.json", refresh, last_request)
        route = data["routes"][0]
        path = [{"latitude": round(lat, 6), "longitude": round(lon, 6)}
                for lon, lat in route["geometry"]["coordinates"]]
        out.append({
            "id": route_id,
            "title": title,
            "runCount": runs,
            "distanceMeters": round(route["distance"]),
            "stopPlaceIds": [b["id"] for b in stops],
            "stopNames": [b["name"] for b in stops],
            "path": path,
        })
        print(f"{route_id} {title}: {len(stops)} 站, {round(route['distance'])} m, {len(path)} 點, {runs} 人")
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n")
    print(f"已寫入 {OUT.relative_to(ROOT)}（{len(out)} 條）")


if __name__ == "__main__":
    main()
