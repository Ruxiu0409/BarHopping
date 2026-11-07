#!/usr/bin/env python3
"""Merge licensed Taichung sources. Default is offline; --geocode is a one-time batch."""
import argparse
import collections
import datetime as dt
import difflib
import hashlib
import io
import json
import math
from pathlib import Path
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request
import zipfile
import csv

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools/osm'))
import fetch_taichung as osm
DATA = osm.DATA
RAW = HERE / 'raw'
CACHE = HERE / 'geocoding-cache'
UA = osm.USER_AGENT
NOMINATIM = 'https://nominatim.openstreetmap.org/search'
POLICY = 'https://operations.osmfoundation.org/policies/nominatim/'
INDUSTRIES = ('名稱', '名稱1', '名稱2', '名稱3')
CODES = ('行業代號', '行業代號1', '行業代號2', '行業代號3')
NON_BAR = re.compile('視唱|視聽|歌唱|卡拉|舞場|舞廳|夜店|旅館|理容|菸酒|批發|製造|雪茄')
BAR_BUSINESS = re.compile('酒吧|酒館|居酒屋|酒場|餐酒|精釀|調酒|飲酒店')
last_request = 0.0


def norm(s):
    return re.sub(r'\s+', '', unicodedata.normalize('NFKC', s or '')).replace('台', '臺').replace('―', '-').replace('之', '-')


def distance(a, b):
    a, b = a['coordinate'], b['coordinate']
    lat = math.radians((a['latitude'] + b['latitude']) / 2)
    return math.hypot((a['longitude'] - b['longitude']) * math.cos(lat),
                      a['latitude'] - b['latitude']) * 111320


def label(x):
    s = norm(x['name']).lower()
    if 'brand' in x:
        s = re.sub(r'7\s*[-–]?\s*(eleven|11)|統一超商|familymart|全家便利商店|全家', '', s)
        s = re.sub(r'(門市|分店|店)$', '', s)
    return re.sub(r'[^\w\u4e00-\u9fff]', '', s)


def duplicate(x, existing):
    for y in sorted(existing, key=lambda y: distance(x, y)):
        if x.get('brand') != y.get('brand'):
            continue
        meters = distance(x, y)
        if meters > 180:
            break
        a, b = label(x), label(y)
        similar = bool(a and b and (a == b or (min(len(a), len(b)) >= 2 and (a in b or b in a))
                                  or difflib.SequenceMatcher(None, a, b).ratio() >= .8))
        if (meters <= 150 and similar) or ('brand' in x and meters <= 60):
            return {'keptId': y['id'], 'keptName': y['name'], 'distanceMeters': round(meters, 1),
                    'reason': '名稱相近且距離≤150m' if similar else '同品牌且距離≤60m'}
    return None


def inside(x, ring):
    c = x['coordinate']
    return math.isfinite(c['latitude']) and math.isfinite(c['longitude']) and osm.contains(ring, (c['longitude'], c['latitude']))


def tax_rows():
    with zipfile.ZipFile(RAW / 'tax.zip') as z:
        with io.TextIOWrapper(z.open('BGMOPEN1.csv'), encoding='utf-8-sig') as f:
            return [r for r in csv.DictReader(f) if norm(r['營業地址']).startswith('臺中市')]


def candidate_reason(r):
    text = ' '.join(r[k] for k in INDUSTRIES) + ' ' + r['營業人名稱']
    if NON_BAR.search(text):
        return 'KTV／歌唱／舞場／夜店／旅館／理容／菸酒零售批發／製造業'
    for reason, pattern in osm.EXCLUSIONS:
        if pattern.search(r['營業人名稱']):
            return reason
    if not BAR_BUSINESS.search(r['營業人名稱']):
        return '僅飲酒店登記，名稱無酒吧證據，無法確認對外店名'
    if not any(r[k] in ('餐廳', '飲酒店', '麵店、小吃店') for k in INDUSTRIES):
        return '缺少餐飲／飲酒店行業證據'
    return None


def parse_address(address):
    s = norm(address)
    m = re.fullmatch(r'臺中市(?P<district>[^區]+區)(?:[^里]+里)?(?:\d+鄰)?(?P<street>.+?)(?P<house>\d+(?:-\d+)?)號(?P<floor>.*)', s)
    if not m or re.search('[、,]|至|北邊', m['street']):
        return None
    return m.groupdict()


def geocode(address, allow_network):
    global last_request
    parts = parse_address(address)
    if not parts:
        return None, {'reason': '門牌格式不明確或多門牌，不猜測'}
    # The district is validated in the result. A structured street query avoids
    # relying on Nominatim's parsing of Taiwan's village and floor components.
    query = {'street': parts['house'] + ' ' + parts['street'], 'city': '臺中市',
             'format': 'jsonv2', 'addressdetails': '1', 'limit': '5', 'countrycodes': 'tw'}
    key = hashlib.sha256(json.dumps(query, sort_keys=True, ensure_ascii=False).encode()).hexdigest()
    path = CACHE / (key + '.json')
    if path.exists():
        cached = json.loads(path.read_text())
    elif allow_network:
        time.sleep(max(0, 1.1 - (time.monotonic() - last_request)))
        url = NOMINATIM + '?' + urllib.parse.urlencode(query)
        last_request = time.monotonic()
        # Stop on HTTP errors rather than repeatedly querying a rejecting server.
        with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=45) as response:
            results = json.load(response)
        if not isinstance(results, list):
            raise ValueError('Unexpected Nominatim response')
        cached = {'query': query, 'url': url, 'fetchedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'results': results}
        osm.write_json(path, cached)
    else:
        raise FileNotFoundError(f'Missing geocoding cache {key}; preserve existing caches or deliberately run the one-time --geocode mode. No catalog files were written.')
    matches = []
    for r in cached['results']:
        a = r.get('address', {})
        road = norm(a.get('road', ''))
        house = norm(a.get('house_number', '')).removesuffix('號')
        district = norm(a.get('suburb', a.get('city_district', '')))
        city = norm(a.get('city', ''))
        # Never accept street/district centroids or interpolated nearby numbers.
        if house == parts['house'] and road == parts['street'] and district == parts['district'] and city == '臺中市' and r.get('place_rank') == 30:
            matches.append(r)
    if len(matches) != 1:
        return None, {'reason': '無唯一精確門牌結果（路段／行政區／不相符門牌均排除）', 'cacheKey': key,
                      'resultCount': len(cached['results']), 'exactMatches': len(matches)}
    r = matches[0]
    return {'latitude': float(r['lat']), 'longitude': float(r['lon'])}, {
        'cacheKey': key, 'osmId': f"{r['osm_type']}/{r['osm_id']}", 'query': query,
        'fetchedAt': cached['fetchedAt'], 'precision': 'exact house number; not verified entrance'}


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--geocode', action='store_true', help='one-time small batch only; cache all responses, single machine/thread, ≥1.1s apart')
    args = ap.parse_args()
    if args.geocode:
        print(f'Nominatim policy: {POLICY}. One-time batch, single machine/thread, ≤1 req/s; do not schedule this flag.', flush=True)
    ring = json.loads((DATA / 'taichung-service-area.json').read_text())['coordinates'][0]
    response = osm.fetch('places', False)
    bars, stores, _ = osm.catalogs(response)
    original = {'bars': len(bars), **dict(collections.Counter(s['brand'] for s in stores))}
    sources = {k: json.loads((RAW / (k + '-request.json')).read_text()) for k in ('tax', 'coolmap', 'tourism')}
    report = {'sources': sources, 'baseline': original, 'added': [], 'duplicates': [], 'excluded': [], 'geocoding': [],
              'deduplication': '既有 OSM 優先；同品牌≤60m 或名稱相近≤150m。不同來源依 OSM、Cool Map、稅籍順序保留。',
              'nominatimPolicy': POLICY, 'requiredAppAttributions': [
                  '環境部氣候變遷署（2026）Cool map涼適點點位，政府資料開放授權條款第1版 https://data.gov.tw/license',
                  '財政部財政資訊中心（2026）全國營業(稅籍)登記資料集，政府資料開放授權條款第1版 https://data.gov.tw/license',
                  '© OpenStreetMap contributors，ODbL-1.0 https://www.openstreetmap.org/copyright'],
              'appAttributionPending': True}

    def merge(x, target, evidence):
        record = {'id': x['id'], 'name': x['name'], 'kind': x.get('brand', 'bars'), **evidence}
        if not inside(x, ring):
            report['excluded'].append({**record, 'reason': '服務範圍外或無效座標'})
        elif match := duplicate(x, target):
            report['duplicates'].append({**record, **match})
        else:
            # A matching branch hundreds of meters away may be a move or a bad
            # source coordinate. Retain OSM and leave the new record for review.
            conflicts = [y for y in target if x.get('brand') and x.get('brand') == y.get('brand')
                         and min(len(label(x)), len(label(y))) >= 2
                         and (label(x).endswith(label(y)) or label(y).endswith(label(x)))
                         and distance(x, y) <= 1000]
            if conflicts:
                y = min(conflicts, key=lambda y: distance(x, y))
                report['excluded'].append({**record, 'reason': '同分店名稱但座標相距>150m，保留既有資料待確認',
                                           'keptId': y['id'], 'distanceMeters': round(distance(x, y), 1)})
                return
            target.append(x)
            report['added'].append(record)

    expansion_path = ROOT / 'tools/osm/raw/expanded.json'
    if not expansion_path.exists():
        raise FileNotFoundError('Missing OSM expansion cache; see README.md')
    expansion = json.loads(expansion_path.read_text())
    if expansion.get('remark'):
        raise ValueError('Incomplete Overpass response')
    report['sources']['osmExpansion'] = {**json.loads((expansion_path.parent / 'expanded-request.json').read_text()),
                                         'license': 'ODbL-1.0', 'timestamp': expansion['osm3s']['timestamp_osm_base']}
    known = {b['id'] for b in bars}
    for e in expansion['elements']:
        t = e.get('tags', {})
        name = osm.name_of(t)
        if not osm.BAR_NAME.search(name) or osm.common(e)['id'] in known:
            continue
        reason = next((r for r, p in osm.EXCLUSIONS if p.search(name)), None)
        # An explicit retail/office/lodging tag overrides the name heuristic.
        if t.get('shop') or t.get('office') or t.get('tourism') or t.get('amenity') not in ('bar', 'pub', 'biergarten', 'restaurant', 'cafe', 'fast_food'):
            reason = reason or '零售／辦公／旅宿／非餐飲標籤，名稱不足以確認酒吧'
        if reason:
            report['excluded'].append({'id': osm.common(e)['id'], 'name': name, 'kind': 'bars', 'source': 'osmExpansion', 'reason': reason})
        else:
            merge({**osm.common(e), 'name': name, 'category': 'pub' if t.get('amenity') in ('pub', 'biergarten') else 'bar',
                   'updatedAt': expansion['osm3s']['timestamp_osm_base']}, bars, {'source': 'osmExpansion', 'tags': t})

    cool = json.loads((RAW / 'coolmap.json').read_text())
    if not cool.get('success') or len(cool['payload']['records']) != cool['payload']['total']:
        raise ValueError('Incomplete Cool Map download')
    rows = cool['payload']['records']
    report['coolmapTotal'] = len(rows)
    report['coolmapTaichungByType'] = dict(collections.Counter(r['coolingtype'] for r in rows if norm(r['city']) == '臺中市'))
    seen = set()
    for r in sorted(rows, key=lambda r: r['recordid']):
        if norm(r['city']) != '臺中市' or r['coolingtype'] not in ('統一超商', '全家便利商店'):
            continue
        sid = r['recordid'].strip()
        if not sid or sid in seen:
            raise ValueError(f'Missing/duplicate Cool Map stable ID: {sid}')
        seen.add(sid)
        brand = '7-ELEVEN' if r['coolingtype'] == '統一超商' else '全家'
        detail = re.sub(r'^(統一超商|全家便利商店)[-－\s]*', '', r['placename'])
        addr = norm(r['address'])
        if not addr.startswith('臺中市'):
            addr = '臺中市' + ('' if addr.startswith(norm(r['district'])) else norm(r['district'])) + addr
        try:
            coord = {'latitude': float(r['latitude']), 'longitude': float(r['longitude'])}
        except (ValueError, TypeError):
            report['excluded'].append({'id': 'moenv-coolmap-' + sid, 'name': r['placename'], 'kind': brand, 'source': 'coolmap', 'reason': '無有效座標'})
            continue
        merge({'id': 'moenv-coolmap-' + sid, 'brand': brand, 'name': brand + ' ' + detail,
               'coordinate': coord, 'address': addr, 'openingHoursText': r['openinghours'] or None,
               'source': 'moenv-coolmap', 'sourceId': 'GIS_P_82/' + sid}, stores,
              {'source': 'coolmap', 'sourceName': r['placename'], 'importDate': r['ImportDate']['date']})

    tax = tax_rows()
    report['taxTaichungRows'] = len(tax)
    report['otherBrands'] = dict(collections.Counter('萊爾富' if '萊爾富' in r['營業人名稱'] else 'OK' for r in tax if any(n in r['營業人名稱'] for n in ('萊爾富', '來來超商'))))
    report['otherBrands'].setdefault('OK', 0)
    other_osm = collections.Counter()
    for e in response['elements']:
        t = e.get('tags', {})
        text = ' '.join(t.get(k, '') for k in ('name', 'brand'))
        if t.get('shop') != 'convenience' or not inside(osm.common(e), ring):
            continue
        if re.search('萊爾富|hi.?life', text, re.I):
            other_osm['萊爾富'] += 1
        elif re.search('來來超商|OK.?mart|OK便利|OK超商', text, re.I):
            other_osm['OK'] += 1
    report['otherBrandsOSMWithinServiceArea'] = dict(other_osm)
    report['taxTargetBrandRegistrations'] = dict(collections.Counter('7-ELEVEN' if '統一超商' in r['營業人名稱'] else '全家' for r in tax if any(n in r['營業人名稱'] for n in ('統一超商', '全家便利商店'))))
    candidates = [r for r in tax if osm.BAR_NAME.search(r['營業人名稱']) or any(r[k] == '563114' for k in CODES)]
    report['taxBarCandidates'] = len(candidates)
    for r in sorted(candidates, key=lambda r: r['統一編號']):
        rec = {'id': 'mof-tax-' + r['統一編號'], 'name': r['營業人名稱'], 'kind': 'bars', 'source': 'tax',
               'address': r['營業地址'], 'industries': {k: r[k] for k in INDUSTRIES}}
        if reason := candidate_reason(r):
            report['excluded'].append({**rec, 'reason': reason})
            continue
        coord, evidence = geocode(r['營業地址'], args.geocode)
        report['geocoding'].append({**rec, **evidence, 'acceptedExactAddress': coord is not None})
        print(r['營業人名稱'], 'exact' if coord else evidence['reason'], flush=True)
        if coord is None:
            report['excluded'].append({**rec, **evidence})
            continue
        merge({'id': rec['id'], 'name': rec['name'], 'category': 'bar', 'coordinate': coord,
               'address': norm(r['營業地址']), 'openingHoursText': None, 'source': 'mof-tax',
               'sourceId': '9400/' + r['統一編號'], 'updatedAt': sources['tax']['fetchedAt']}, bars, {'source': 'tax', 'geocoding': evidence})

    tourism = json.loads(zipfile.ZipFile(RAW / 'tourism.zip').read('RestaurantList.json'))
    tourist_rows = [r for r in tourism['Restaurants'] if r['PostalAddress']['City'] == '臺中市']
    report['tourismConsidered'] = {'taichungRows': len(tourist_rows), 'nameMatchedBars': sum(bool(osm.BAR_NAME.search(r['RestaurantName'])) for r in tourist_rows), 'used': False, 'reason': '臺中餐飲資料中沒有名稱符合酒吧規則的候選'}
    report['counts'] = {'bars': len(bars), **dict(collections.Counter(s['brand'] for s in stores))}
    for key in ('added', 'duplicates', 'excluded'):
        report[key + 'Counts'] = dict(collections.Counter(x['kind'] for x in report[key]))
    report['geocodingCounts'] = {'attemptedCandidates': len(report['geocoding']), 'exact': sum(x['acceptedExactAddress'] for x in report['geocoding']),
                                 'failedOrImprecise': sum(not x['acceptedExactAddress'] for x in report['geocoding'])}
    assert len({x['id'] for x in bars + stores}) == len(bars + stores)
    assert all(inside(x, ring) for x in bars + stores)
    assert all(x['brand'] in ('7-ELEVEN', '全家') for x in stores)
    for xs, filename in ((bars, 'taichung-bars.json'), (stores, 'taichung-convenience-stores.json')):
        osm.write_json(DATA / filename, sorted(xs, key=lambda x: x['id']))
    # The overall catalog uses acquisition time; retain OSM's database timestamp
    # separately instead of pretending the government sources are OSM updates.
    osm.write_json(DATA / 'taichung-data-metadata.json', {
        'placeDataUpdatedAt': max(s['fetchedAt'] for s in sources.values()),
        'osmPlaceDataUpdatedAt': response['osm3s']['timestamp_osm_base'],
        'fetchedAt': max(s['fetchedAt'] for s in sources.values()),
        'sources': report['sources'], 'counts': report['counts'],
        'requiredAppAttributions': report['requiredAppAttributions'], 'appAttributionPending': True})
    osm.write_json(HERE / 'report.json', report)
    osm_report = json.loads((ROOT / 'tools/osm/report.json').read_text())
    osm_report['mergedCatalog'] = {'report': '../catalog/report.json', 'counts': report['counts'], 'baseline': original}
    osm.write_json(ROOT / 'tools/osm/report.json', osm_report)
    print(json.dumps({k: report[k] for k in ('counts', 'addedCounts', 'duplicatesCounts', 'excludedCounts', 'geocodingCounts')}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
