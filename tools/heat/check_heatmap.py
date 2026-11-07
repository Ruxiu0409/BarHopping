#!/usr/bin/env python3
"""以 App 原始 Swift Core 驗證 JSON 解碼及熱力圖，暫存編譯成品執行後自動移除。

python3 tools/heat/check_heatmap.py           # release -O
python3 tools/heat/check_heatmap.py --debug   # debug -Onone
不編譯 iOS、不使用模擬器，不計 MapLibre 或手機上的渲染時間。
"""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
CORE = ROOT / 'BarHopping/BarHopping/Core'
DATA = CORE.parent / 'Resources/Data/taichung-demo-popular-routes.json'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--debug', action='store_true')
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix='bh-heat-check-') as work:
        binary = str(Path(work) / 'check')
        subprocess.run(['xcrun', 'swiftc', '-Onone' if args.debug else '-O',
                        '-module-cache-path', str(Path(work) / 'module-cache'),
                        str(CORE / 'Models.swift'), str(CORE / 'PopularRoute.swift'),
                        str(CORE / 'PopularRouteHeatmap.swift'),
                        str(Path(__file__).with_suffix('.swift')), '-o', binary], check=True)
        result = subprocess.run([binary, str(DATA)], check=True, capture_output=True, text=True)
        report = json.loads(result.stdout)
        report['optimization'] = 'debug -Onone' if args.debug else 'release -O'
        print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
