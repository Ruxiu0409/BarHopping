#!/usr/bin/env python3
"""Download licensed source snapshots serially; never geocode on refresh."""
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
import sys
import time
import urllib.parse
import urllib.request
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools/osm'))
import fetch_taichung as osm

SOURCES = {
    'tax': ('https://data.gov.tw/dataset/9400', 'https://eip.fia.gov.tw/data/BGMOPEN1.zip', 'tax.zip', None),
    'coolmap': ('https://data.gov.tw/dataset/177893', 'https://data.moenv.gov.tw/api/frontstage/datastore.search', 'coolmap.json',
                {'resource_id': '8e0bda24-9d41-4e83-a54e-a19ecc2cb9c3', 'limit': 20000, 'offset': 0}),
    'tourism': ('https://data.gov.tw/dataset/7779', 'https://media.taiwan.net.tw/XMLReleaseAll_public/v2.0/Zh_tw/Restaurant-json.zip', 'tourism.zip', None),
}
EXPANDED_QUERY = '[out:json][timeout:180];' + osm.AREA + 'nwr(area.city)[name~"酒吧|酒館|居酒屋|酒場|精釀|調酒|[Bb][Ii][Ss][Tt][Rr][Oo]|[Bb][Aa][Rr]|[Pp][Uu][Bb]|[Ll][Oo][Uu][Nn][Gg][Ee]"];out center tags;'


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--refresh', action='store_true', help='replace all snapshots; default downloads missing files only')
    args = ap.parse_args()
    for key, (dataset, url, filename, body) in SOURCES.items():
        path = HERE / 'raw' / filename
        if path.exists() and not args.refresh:
            continue
        headers = {'User-Agent': osm.USER_AGENT}
        if body:
            headers['Content-Type'] = 'application/json'
        req = urllib.request.Request(url, data=json.dumps(body).encode() if body else None, headers=headers)
        with urllib.request.urlopen(req, timeout=180) as r:
            raw = r.read()
        if filename.endswith('.zip'):
            import io
            with zipfile.ZipFile(io.BytesIO(raw)) as z:
                if z.testzip():
                    raise ValueError('Corrupt ZIP')
        else:
            d = json.loads(raw)
            if not d.get('success') or len(d['payload']['records']) != d['payload']['total']:
                raise ValueError('Incomplete Cool Map data; update pagination before use')
        path.parent.mkdir(exist_ok=True, parents=True)
        path.write_bytes(raw)
        osm.write_json(path.parent / (key + '-request.json'), {
            'datasetUrl': dataset, 'downloadUrl': url, 'requestBody': body,
            'fetchedAt': dt.datetime.now(dt.timezone.utc).isoformat(),
            'license': '政府資料開放授權條款第1版', 'licenseUrl': 'https://data.gov.tw/license',
            'sha256': hashlib.sha256(raw).hexdigest()})
        print(key, len(raw), flush=True)
        time.sleep(1)
    path = ROOT / 'tools/osm/raw/expanded.json'
    if args.refresh or not path.exists():
        time.sleep(5)
        req = urllib.request.Request(osm.ENDPOINT, data=urllib.parse.urlencode({'data': EXPANDED_QUERY}).encode(), headers={'User-Agent': osm.USER_AGENT})
        with urllib.request.urlopen(req, timeout=240) as r:
            raw = r.read()
        d = json.loads(raw)
        if d.get('remark') or not d.get('elements') or not d.get('osm3s', {}).get('timestamp_osm_base'):
            raise ValueError('Incomplete Overpass response')
        path.parent.mkdir(exist_ok=True, parents=True)
        path.write_bytes(raw)
        osm.write_json(path.parent / 'expanded-request.json', {
            'fetchedAt': dt.datetime.now(dt.timezone.utc).isoformat(), 'query': EXPANDED_QUERY, 'endpoint': osm.ENDPOINT})
        print('osmExpansion', len(d['elements']))


if __name__ == '__main__':
    main()
