#!/usr/bin/env python3
"""Verify actual merged artifacts, baseline preservation, accounting, and cache coverage."""
import collections
import hashlib
import json
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
import expand_taichung as catalog


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    names = ('taichung-bars.json', 'taichung-convenience-stores.json', 'taichung-data-metadata.json')
    paths = [catalog.DATA / name for name in names] + [HERE / 'report.json', ROOT / 'tools/osm/report.json']
    before = {str(p.relative_to(ROOT)): digest(p) for p in paths}
    subprocess.run([sys.executable, str(HERE / 'expand_taichung.py')], check=True, stdout=subprocess.DEVNULL)
    assert before == {str(p.relative_to(ROOT)): digest(p) for p in paths}, 'Offline rebuild changed outputs'
    bars, stores = [json.loads((catalog.DATA / n).read_text()) for n in names[:2]]
    base_bars, base_stores, _ = catalog.osm.catalogs(catalog.osm.fetch('places', False))
    for originals, merged in ((base_bars, bars), (base_stores, stores)):
        by_id = {x['id']: x for x in merged}
        assert all(by_id.get(x['id']) == x for x in originals), 'OSM baseline altered'
    ring = json.loads((catalog.DATA / 'taichung-service-area.json').read_text())['coordinates'][0]
    assert all(catalog.inside(x, ring) for x in bars + stores)
    assert len({x['id'] for x in bars + stores}) == len(bars + stores)
    assert set(x['brand'] for x in stores) == {'7-ELEVEN', '全家'}
    common = {'id', 'name', 'coordinate', 'address', 'openingHoursText', 'source', 'sourceId'}
    assert all(set(x) == common | {'category', 'updatedAt'} for x in bars)
    assert all(set(x) == common | {'brand'} for x in stores)
    report = json.loads((HERE / 'report.json').read_text())
    candidates = {'bars': report['taxBarCandidates'] + sum(x.get('source') == 'osmExpansion' for key in ('added', 'duplicates', 'excluded') for x in report[key]),
                  '7-ELEVEN': report['coolmapTaichungByType']['統一超商'], '全家': report['coolmapTaichungByType']['全家便利商店']}
    for kind, count in candidates.items():
        assert count == sum(report[k].get(kind, 0) for k in ('addedCounts', 'duplicatesCounts', 'excludedCounts'))
        assert report['counts'][kind] == report['baseline'][kind] + report['addedCounts'].get(kind, 0)
    for r in report['geocoding']:
        if 'cacheKey' in r:
            assert (catalog.CACHE / (r['cacheKey'] + '.json')).exists()
    for key in ('tax', 'coolmap', 'tourism'):
        meta = report['sources'][key]
        filename = {'tax': 'tax.zip', 'coolmap': 'coolmap.json', 'tourism': 'tourism.zip'}[key]
        assert digest(catalog.RAW / filename) == meta['sha256']
    print(json.dumps({'status': 'passed', 'counts': report['counts'], 'candidates': candidates,
                      'checks': ['offline rebuild byte-identical', 'all OSM records preserved', 'all coordinates inside service area',
                                 'stable unique IDs', 'unchanged record schemas', 'only two permitted brands',
                                 'candidate counts reconciled', 'geocoding caches present', 'source SHA-256 verified'],
                      'sha256': before}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
