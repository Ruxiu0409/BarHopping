# 臺中市 OSM 資料匯入

需要 Python 3.9 以上，僅使用標準函式庫。從專案根目錄執行：

```sh
python3 tools/osm/fetch_taichung.py --refresh
```

連線至 `https://overpass-api.de/api/interpreter`，User-Agent 為
`BarHopping-dev/0.1 (student project)`。所有查詢串行執行，每次請求至少間隔
5 秒；失敗後依序等待 15、30、60 秒，最多嘗試四次。錯誤或不完整回應不會當成成功資料。

成功的原始回應及查詢、實際下載時間保存在 `tools/osm/raw/`，此資料夾不納入 Git。
不帶 `--refresh` 時重用原始快取，可修改篩選規則後離線重建，不需要再打 Overpass。
資料輸出會覆寫下列檔案，請一併檢查後交由主代理提交：

- `BarHopping/BarHopping/Resources/Data/taichung-bars.json`
- `BarHopping/BarHopping/Resources/Data/taichung-convenience-stores.json`
- `BarHopping/BarHopping/Resources/Data/taichung-service-area.json`
- `BarHopping/BarHopping/Resources/Data/taichung-data-metadata.json`
- `tools/osm/report.json`，包含每個主要／補充／排除項目的 OSM ID 與理由。

重新下載後須依 `report.json` 更新 `docs/data-sources.md` 的日期、筆數和排除清單。
JSON 放在專案同步資料夾內，Xcode 會自動打包，不需修改專案檔。

## 篩選與轉換

範圍為 `area["name"="臺中市"]["boundary"="administrative"]`。主要集合是
`amenity=bar/pub/biergarten`，biergarten 轉成 pub。補充集合限 restaurant/cafe，
店名符合 `BAR_NAME` 關鍵字，category 轉成 bar。nightclub 不查詢、不納入。
英文詞以 ASCII 字母判斷界線，能辨識「怪Bar」「Bistro88」，又不會把 barbecue 當成 Bar。

`EXCLUSIONS` 列出 KTV／卡拉 OK、RICE／COFFEE／Pizza／Salad／飲料 bar、
喫茶小舖、菸酒零售名稱規則，適用於主要及補充集合。這些是可編輯的名稱啟發式規則，
不是營業型態的人工認證。修改時請檢查報告中的全部名稱。

名稱依序使用 `name`、`name:zh-Hant`、`name:zh`、`name:en`；全部缺少才排除。
地址優先使用 `addr:full`，否則依臺灣地址順序組合 `addr:city/district/suburb/`
`neighbourhood/street/place/lane/alley/housenumber/floor`，補上巷、弄、號、樓。
只有城市或行政區時地址為 null；不補造街道門牌。營業時間保留 `opening_hours` 原文。
node 使用本身座標，way/relation 使用 Overpass center。ID 保留 OSM 元素種類，
不依名稱或距離合併不同元素，更新日期使用 `timestamp_osm_base`。

超商限 `shop=convenience`，由 brand/name 或 brand:wikidata 辨識：
7-ELEVEN 使用 Q259340，全家使用 Q703557。名稱支援 7-11、統一超商、
7-Eleven、FamilyMart、全家便利商店等別名。分店資訊來自 name/branch。

行政邊界另以 `rel(pivot.city)[admin_level=4];out geom;` 取得，依端點連接 outer ways。
使用最大外環，再以本地公尺投影的 Douglas–Peucker 簡化至 100–300 個點，
檢查每間酒吧仍在範圍內。若無法滿足條件則停止，不改用矩形範圍。
目前 Polygon 契約不表達內洞或多個分離外環，報告保留原始外環數。

## 驗證

腳本會檢查回應完整性、邊界閉合與酒吧涵蓋；重新產生後也應使用 App 實際的
`JSONCoding` 解碼 Place、ConvenienceStore、GeoJSONPolygon，測試 bbox 與品牌篩選，
並執行專案編譯。App 只讀取內附資料，不在執行時連線至 Overpass。

資料為 © OpenStreetMap contributors，依 [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/)
提供，詳見 [OSM 著作權與授權](https://www.openstreetmap.org/copyright)
及 [專案資料來源說明](../../docs/data-sources.md)。
