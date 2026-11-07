# 資料來源與授權

App 內附的臺中市地點目錄與服務範圍來自 OpenStreetMap，經
[Overpass API](https://overpass-api.de/api/interpreter) 下載與整理。
資料為 © OpenStreetMap contributors，依
[Open Database License 1.0（ODbL）](https://opendatacommons.org/licenses/odbl/1-0/) 提供。
使用或散布這份衍生資料庫時須保留來源標示，並依 ODbL 的相同授權要求提供資料。
詳見 [OpenStreetMap 著作權與授權說明](https://www.openstreetmap.org/copyright)。
此資料授權不改變 App 程式碼本身的授權。

抓取日期為 2026-11-07，地點下載時間為 04:26:57 UTC（臺灣時間 12:26:57）。
地點資料庫時間 `timestamp_osm_base` 為 **2026-11-07T04:25:06Z**，
App 的 `Place.updatedAt` 與 `config.placeDataUpdatedAt` 使用此時間。
行政邊界時間另記錄於 `tools/osm/report.json`。

## 本次資料

- 酒吧共 55 筆，主要集合 26 筆、restaurant/cafe 名稱補充集合 29 筆。
- 主要集合原有 35 筆，包含 bar、pub、biergarten。biergarten 轉為 pub。
- 主要集合 9 筆沒有 `name`，其中 4 筆有 `name:en`，保留英文名稱；其餘 5 筆排除。
- 7-ELEVEN 747 筆、全家 507 筆，共 1,254 筆超商。
- 行政邊界為 OSM `relation/2921154`，原外環 9,614 點，
  Douglas–Peucker 容差 312.5 公尺，簡化後為含閉合點的 162 點 Polygon。
  全部 55 間酒吧都在原始及簡化後邊界內。

候選集合排除 13 筆：5 筆無名稱、2 筆 KTV、4 筆餐飲／咖啡／飲料 bar、
1 筆手搖飲料連鎖店、1 筆菸酒零售店。具名排除項目為金旺菸酒、時時香RICE BAR、
Salut Pizza Bar 比薩店、喫茶小舖、向陽蔬食飲料Bar、銀櫃KTV、美樂地KTV、
ODD EVEN COFFEE BAR。

無名稱項目的來源識別碼為 `node/4660530034`、`node/6304966303`、
`way/527008414`、`way/549623399`、`way/1323001830`。
每筆主要集合、補充集合與排除原因均列在 `tools/osm/report.json`；
nightclub 與不符合名稱條件的一般餐廳／咖啡店未納入候選集合。

## 已知限制

OSM 的台中酒吧資料不完整，店家可能缺少名稱、地址、營業時間或更新。
restaurant/cafe 的補充集合依名稱判斷，可能誤收餐廳，也會漏掉沒有關鍵字的酒吧。
未逐店確認是否仍營業，也不判斷當下營業狀態。營業時間為 OSM 原文，僅供參考。

超商品牌、分店名稱與地址同樣可能缺漏。以 OSM 元素 ID 區分資料，不合併不同
node/way 的疑似重複店家。way/relation 採中心點，不能視為實際出入口。
服務範圍經過簡化，邊界附近有近似誤差，不應作為精確行政界線或可步行性判斷。

目前 App 的路線仍由 MockBarHoppingAPI 產生示範幾何，未接上真實步行路由。
資料是內附快照，App 不會自動下載更新。重建方式見
[OSM 匯入工具說明](../tools/osm/README.md)。

底圖樣式使用 [OpenFreeMap dark](https://tiles.openfreemap.org/styles/dark)，
config 保留 `© OpenStreetMap contributors` 與 [OpenFreeMap](https://openfreemap.org) 標示。
