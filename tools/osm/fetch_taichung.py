#!/usr/bin/env python3
"""Regenerate the bundled Taichung OSM catalog using only the Python standard library."""

import argparse
import collections
import datetime
import json
import math
from pathlib import Path
import re
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
DATA = ROOT / "BarHopping/BarHopping/Resources/Data"
ENDPOINT = "https://overpass-api.de/api/interpreter"
USER_AGENT = "BarHopping-dev/0.1 (student project)"
AREA = 'area["name"="臺中市"]["boundary"="administrative"]->.city;'
QUERIES = {
    "places": '[out:json][timeout:180];' + AREA + '''(
      nwr(area.city)[amenity~"^(bar|pub|biergarten|restaurant|cafe)$"];
      nwr(area.city)[shop=convenience];
    );out center tags;''',
    "boundary": '[out:json][timeout:180];' + AREA +
                'rel(pivot.city)[admin_level=4];out geom;',
}

# English words must stand alone: "Bar" must not match "barbecue" or "Barbara".
BAR_NAME = re.compile(r"酒吧|酒館|餐酒館|居酒屋|精釀|調酒|威士忌|酒場|"
                      r"(?<![a-z])(?:bar|pub|bistro|tap|lounge|whisky|whiskey)(?![a-z])", re.I)
# Apply to both primary and supplemental candidates. Keep these rules explicit so
# catalog editors can change them without changing the import pipeline.
EXCLUSIONS = [
    ("KTV／卡拉 OK", re.compile(r"ktv|卡拉\s*ok", re.I)),
    ("餐飲／咖啡／飲料 bar", re.compile(
        r"(?<![a-z0-9])(?:rice|coffee|pizza|salad)\s*bar(?![a-z0-9])|飲料\s*bar", re.I)),
    ("手搖飲料連鎖店", re.compile(r"喫茶小舖")),
    ("菸酒零售店", re.compile(r"菸酒(?:專賣店|行)?$")),
]


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def fetch(kind, refresh):
    path = HERE / "raw" / f"{kind}.json"
    if path.exists() and not refresh:
        return json.loads(path.read_text(encoding="utf-8"))
    for attempt in range(4):
        # Also space successful requests; never issue concurrent Overpass queries.
        time.sleep(5 if attempt == 0 else 15 * 2 ** (attempt - 1))
        request = urllib.request.Request(
            ENDPOINT, data=urllib.parse.urlencode({"data": QUERIES[kind]}).encode(),
            headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(request, timeout=240) as response:
                raw = response.read()
            result = json.loads(raw)
            if result.get("remark"):
                raise ValueError(f"Overpass incomplete response: {result['remark']}")
            if not result.get("elements") or not result.get("osm3s", {}).get("timestamp_osm_base"):
                raise ValueError("Overpass returned no elements or database timestamp")
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
            write_json(HERE / "raw" / f"{kind}-request.json", {
                "fetchedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                "endpoint": ENDPOINT, "query": QUERIES[kind],
            })
            return result
        except (urllib.error.URLError, TimeoutError, ValueError) as error:
            print(f"{kind}: attempt {attempt + 1}/4 failed: {error}", flush=True)
            if attempt == 3:
                raise


def normalized(value):
    return unicodedata.normalize("NFKC", value).strip()


def name_of(tags):
    return next((normalized(tags[key]) for key in ("name", "name:zh-Hant", "name:zh", "name:en")
                 if tags.get(key, "").strip()), "")


def address(tags):
    if tags.get("addr:full"):
        return tags["addr:full"].strip()
    # Do not invent a street address for objects with only a city/district tag.
    if not any(tags.get(k) for k in ("addr:street", "addr:place", "addr:housenumber")):
        return None
    parts = []
    for key in ("city", "district", "suburb", "neighbourhood", "street", "place",
                "lane", "alley", "housenumber", "floor"):
        value = tags.get("addr:" + key, "").strip()
        if not value or value in parts:
            continue
        suffix = {"lane": "巷", "alley": "弄", "housenumber": "號", "floor": "樓"}.get(key)
        if suffix and not value.endswith(suffix):
            value += suffix
        parts.append(value)
    return "".join(parts) or None


def common(element):
    point = element if "lat" in element else element.get("center", {})
    if "lat" not in point or "lon" not in point:
        raise ValueError(f"No coordinate for {element['type']}/{element['id']}")
    tags = element.get("tags", {})
    return {"id": f"osm-{element['type']}-{element['id']}",
            "coordinate": {"latitude": point["lat"], "longitude": point["lon"]},
            "address": address(tags), "openingHoursText": tags.get("opening_hours"),
            "source": "osm", "sourceId": f"{element['type']}/{element['id']}"}


def brand_of(tags):
    wikidata = tags.get("brand:wikidata", "").split(";")
    text = " ".join(normalized(tags.get(k, "")) for k in ("brand", "name"))
    if "Q259340" in wikidata or re.search(r"7\s*[-–]?\s*(?:eleven|11)|統一超商", text, re.I):
        return "7-ELEVEN"
    if "Q703557" in wikidata or re.search(r"family\s*mart|全家", text, re.I):
        return "全家"
    return None


def store_name(tags, brand):
    name, branch = name_of(tags), normalized(tags.get("branch", ""))
    # Remove the brand prefix, then retain the name's existing branch information.
    detail = re.sub(r"^(?:7\s*[-–]?\s*(?:eleven|11)|統一超商|family\s*mart|全家(?:便利商店)?)\s*",
                    "", name, flags=re.I).strip(" -_()（）")
    if branch and branch not in detail:
        detail = " ".join(filter(None, [detail, branch]))
    return brand + (" " + detail if detail else "")


def catalogs(response):
    bars, stores, excluded, supplemental, primary = [], [], [], [], []
    for element in response["elements"]:
        tags = element.get("tags", {})
        name = name_of(tags)
        amenity = tags.get("amenity")
        is_primary = amenity in ("bar", "pub", "biergarten")
        is_supplement = amenity in ("restaurant", "cafe") and BAR_NAME.search(name)
        if is_primary or is_supplement:
            reason = "沒有名稱" if not name else next(
                (reason for reason, pattern in EXCLUSIONS if pattern.search(name)), None)
            record = {"sourceId": f"{element['type']}/{element['id']}", "name": name,
                      "amenity": amenity, "collection": "primary" if is_primary else "supplemental"}
            if reason:
                excluded.append({**record, "reason": reason})
            else:
                bars.append({**common(element), "name": name,
                             "category": "pub" if amenity in ("pub", "biergarten") else "bar",
                             "updatedAt": response["osm3s"]["timestamp_osm_base"]})
                (primary if is_primary else supplemental).append(record)
        if tags.get("shop") == "convenience" and (brand := brand_of(tags)):
            stores.append({**common(element), "brand": brand, "name": store_name(tags, brand)})
    return (sorted(bars, key=lambda x: x["id"]), sorted(stores, key=lambda x: x["id"]),
            {"primary": primary, "supplemental": supplemental, "excluded": excluded})


def boundary_rings(response):
    relations = [e for e in response["elements"] if e["type"] == "relation"]
    if len(relations) != 1:
        raise ValueError(f"Expected one Taichung boundary, found {len(relations)}")
    relation = relations[0]
    pieces = [[(p["lon"], p["lat"]) for p in member["geometry"]]
              for member in relation["members"]
              if member["type"] == "way" and member.get("role") == "outer"]
    rings = []
    while pieces:
        ring = pieces.pop(0)
        while ring[0] != ring[-1]:
            for i, piece in enumerate(pieces):
                if ring[-1] == piece[0] or ring[-1] == piece[-1]:
                    ring.extend((piece if ring[-1] == piece[0] else piece[::-1])[1:])
                    pieces.pop(i)
                    break
            else:
                raise ValueError("Boundary ways do not form a closed ring")
        rings.append(ring)
    return rings, f"relation/{relation['id']}"


def contains(ring, point):
    x, y = point
    inside = False
    for (xi, yi), (xj, yj) in zip(ring, ring[1:]):
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
            inside = not inside
    return inside


def distance(point, a, b):
    # Local equirectangular projection to meters at Taichung's latitude.
    def projected(p):
        return (p[0] * 111320 * math.cos(math.radians(24.2)), p[1] * 111320)
    p, a, b = map(projected, (point, a, b))
    dx, dy = b[0] - a[0], b[1] - a[1]
    t = max(0, min(1, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / (dx * dx + dy * dy))) if dx or dy else 0
    return math.hypot(p[0] - a[0] - t * dx, p[1] - a[1] - t * dy)


def douglas_peucker(points, tolerance):
    if len(points) <= 2:
        return points
    index, maximum = max(((i, distance(p, points[0], points[-1]))
                          for i, p in enumerate(points[1:-1], 1)), key=lambda x: x[1])
    if maximum <= tolerance:
        return [points[0], points[-1]]
    return douglas_peucker(points[:index + 1], tolerance)[:-1] + douglas_peucker(points[index:], tolerance)


def simplify_boundary(rings, bars):
    # The contract supports Polygon rather than MultiPolygon. Choose the largest
    # land ring; fail rather than silently omit any bar on a disconnected island.
    def area(ring):
        return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(ring, ring[1:])))
    ring = max(rings, key=area)
    points = [(b["coordinate"]["longitude"], b["coordinate"]["latitude"]) for b in bars]
    if not all(contains(ring, p) for p in points):
        raise ValueError("A bar lies outside the largest original boundary ring")
    # Binary-search a DP tolerance yielding 100–300 points. Reject a candidate
    # that clips a catalog bar; never replace the city with a bounding rectangle.
    low, high = 0.0, 10000.0
    for _ in range(40):
        tolerance = (low + high) / 2
        middle = len(ring) // 2
        simplified = (douglas_peucker(ring[:middle + 1], tolerance)[:-1] +
                      douglas_peucker(ring[middle:], tolerance))
        if len(simplified) > 300:
            low = tolerance
        elif len(simplified) < 100 or not all(contains(simplified, p) for p in points):
            high = tolerance
        else:
            return {"type": "Polygon", "coordinates": [simplified]}, tolerance, len(ring)
    raise ValueError("Cannot simplify boundary to 100–300 vertices while retaining every bar")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--refresh", action="store_true", help="replace cached raw responses from Overpass")
    args = parser.parse_args()
    response = fetch("places", args.refresh)
    boundary = fetch("boundary", args.refresh)
    bars, stores, report = catalogs(response)
    rings, boundary_id = boundary_rings(boundary)
    polygon, tolerance, original_count = simplify_boundary(rings, bars)
    report.update({
        "source": "OpenStreetMap via Overpass", "endpoint": ENDPOINT,
        "license": "ODbL-1.0", "copyright": "https://www.openstreetmap.org/copyright",
        "placeDataUpdatedAt": response["osm3s"]["timestamp_osm_base"],
        "boundaryDataUpdatedAt": boundary["osm3s"]["timestamp_osm_base"],
        "fetchedAt": json.loads((HERE / "raw/places-request.json").read_text())["fetchedAt"],
        "counts": {"bars": len(bars), "primary": len(report["primary"]),
                   "supplemental": len(report["supplemental"]), "excluded": len(report["excluded"]),
                   "convenienceStores": dict(collections.Counter(s["brand"] for s in stores))},
        "boundary": {"sourceId": boundary_id, "originalVertices": original_count,
                     "vertices": len(polygon["coordinates"][0]), "toleranceMeters": tolerance,
                     "outerRings": len(rings)},
    })
    write_json(DATA / "taichung-bars.json", bars)
    write_json(DATA / "taichung-convenience-stores.json", stores)
    write_json(DATA / "taichung-service-area.json", polygon)
    write_json(DATA / "taichung-data-metadata.json", {
        "placeDataUpdatedAt": report["placeDataUpdatedAt"], "fetchedAt": report["fetchedAt"]})
    write_json(HERE / "report.json", report)
    print(json.dumps({"counts": report["counts"], "boundary": report["boundary"],
                      "placeDataUpdatedAt": report["placeDataUpdatedAt"]}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
