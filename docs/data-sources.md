# 資料來源與授權

## 地圖店家詳情補充（2026-11-07）

地圖卡片目前對兩筆既有 OSM 店家 ID 提供補充介紹：Vender Bar 與 Bar MED。
其餘店家仍顯示 App 內附目錄所提供的名稱、地址及營業時間；資料不完整時會明確顯示未提供。
店家介紹及聯絡資訊附有來源連結，營業資訊可能變動，出發前應查看店家最新公告。

- Vender Bar：地址、電話及特色介紹參考 [The 50 的 Vender 店家頁](https://www.the50.com/bars/best-in-asia/the-list/vender.html)。未把第三方照片放進 App，營業時間請以店家公告為準。
- Bar MED：電話、地址及營業時間取自[臺虎精釀官方門市頁](https://www.taihubrewing.com/pages/taihu-retail)；店家風格介紹依[欣傳媒的 Bar MED 專文](https://www.xinmedia.com/article/212385)摘要。卡片顯示的照片使用臺虎官方頁公開的圖片 URL，採遠端載入，不另存或散布圖片檔；官方頁及介紹來源連結都顯示於卡片。
- 若未來來源頁面、圖片位址或營業資訊變更，需同步更新 `Map/PlaceEditorialInfo.swift`。

這些補充資料以現有 OSM ID 對應，不修改共用 `Place` API 契約。未匹配到補充資料的店家不會套用其他店家的介紹或照片。

目前內附目錄為酒吧 **65** 筆、7-ELEVEN **916** 筆、全家 **643** 筆。
2026-11-07 增補使用財政部稅籍資料及環境部 Cool Map，來源、授權、排除與限制見下方
「政府開放資料增補」。以下先保留原始 OSM 快照的來源與統計。

原始臺中市地點目錄與服務範圍來自 OpenStreetMap，經
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

## 原始 OSM 快照

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

## 示範熱門路線熱力圖

`taichung-demo-popular-routes.json` 包含 144 條示範步行路線，混合酒吧串店與地標周邊散步／路跑路徑，每條實際路由長度 1–5 公里。主要覆蓋區名額為西區 24、中區 12、北區 18、南區 14、東區 14、西屯區 24、南屯區 18、北屯區 20。跨區路線只在起點的主要覆蓋組計一次，分組以鄰近地標為準，並非行政界線裁切。涵蓋審計新村、勤美、一中、逢甲、七期，以及南區、東區、北屯、東海等周邊。

產生器讀取 App 內附的 65 間酒吧目錄，保留市區地標 2.5 公里內的酒吧；另外人工選定常見地標附近的概略座標，不宣稱為入口或精確地理編碼。以固定種子 `20261107` 打亂直線距離 850–3,300 公尺的相鄰點對，優先分散端點覆蓋，再按各組名額選取合格路線。相同座標點對去重，沒有新增或捏造店家。`stopPlaceIds` 中的酒吧 ID 沿用目錄，地標使用 `landmark-行政區-序號` 示範 ID，與 `stopNames` 一一對應。

路徑由 [FOSSGIS 步行路由服務](https://routing.openstreetmap.de/) 的 OSRM `routed-foot` 產生。路徑 © OpenStreetMap contributors，採 [ODbL 授權](https://www.openstreetmap.org/copyright)。依[服務使用規範](https://routing.openstreetmap.de/about.html)，單執行緒依序查詢，請求至少間隔 1.5 秒，User-Agent 為 `BarHopping-dev/0.1 (student project)`；失敗最多嘗試三次，退避 10／30 秒並尊重數字秒數的 Retry-After。回應依完整路由 URL 的 SHA-256 雜湊快取到 `tools/heat/raw/`，重跑不重複請求已有路線，失敗的 NoRoute 等回應也保留。超出 1–5 公里、繞行比超過 2.4，或端點吸附超過 100 公尺的路線會跳過並另選候選；原因記在 `tools/heat/report.json`。

`runCount` 仍是人工設定區間後以固定種子抽取的示範數字，範圍 5–250，審計新村、勤美、一中、逢甲、七期較高，外圍較低，並非真實使用者統計。地圖與路跑共用這份示範資料，地圖開啟熱門圖層時標示「示範資料」。公共路由服務僅供開發產生資料，App 顯示熱力圖不會呼叫此服務。

輸出座標保留五位小數並移除連續重複點，JSON 使用緊湊格式，產生器拒絕寫入超過 1.5 MB 的結果。保留道路頂點而不逐路線做 Douglas–Peucker，讓不同路線沿相同道路時仍可依現有一公尺格點合併熱度。

從專案根目錄重跑：

```bash
python3 tools/heat/make_demo_routes.py           # 優先使用快取
python3 tools/heat/make_demo_routes.py --offline # 完全離線；缺快取就停止
python3 tools/heat/check_heatmap.py             # 直接編譯 App Core，驗證解碼與計算
python3 tools/heat/check_heatmap.py --debug     # 相同資料的 debug 計算時間
```

本次輸出共 388,209 公尺，21 條酒吧到酒吧、123 條含地標路線，沒有候選因品質檢查被跳過。JSON 為 637,219 bytes，13,534 個輸入路段去重後為 7,778 邊，再合併為 808 個 feature。直接執行 App Core，在 arm64 macOS 主機各量測一次，最終 JSON 的 release 計算約 43.6 ms、debug 約 333.9 ms，解碼另約 51.6／65.9 ms。相同路徑先前曾量得 12.7／65.3 ms，主機時間有明顯波動。這不是手機渲染時間；詳細數值及輸出 SHA-256 見 `tools/heat/verification.json`。考量 debug 單次計算可能造成主執行緒停頓，建議載入時在背景計算一次並快取結果，本輪不修改 App 端。

固定酒吧輸入、程式與快取下，重跑的 JSON 及產生報告相同。`--refresh` 會重新查詢，路由服務的 OSM 更新可能改變結果。`tools/heat/raw/` 不納入版本控制，另一台電腦首次執行需連網。`check_heatmap.py` 使用暫存目錄並自動清理，回報原始路段、去重路段、合併 feature 數、JSON 解碼與熱力圖運算時間；這是主機上的 Core 計算，不含 MapLibre 渲染或 iPhone 效能。

## 政府開放資料增補（2026-11-07）

本輪增加 10 間酒吧、169 間 7-ELEVEN、136 間全家，共新增 315 個地點。
全部位於既有 `taichung-service-area.json` 範圍，原有 55 間酒吧及 1,254 間超商完整保留。
JSON 欄位、bar/pub 類別及超商品牌不變，未更動 Swift 模型或 UI。

使用來源與 UTC 取得時間：

- 財政部財政資訊中心，[全國營業(稅籍)登記資料集 9400](https://data.gov.tw/dataset/9400)，
  [原始 ZIP](https://eip.fia.gov.tw/data/BGMOPEN1.zip)，2026-11-07 05:18:42 UTC。
  採[政府資料開放授權條款第1版](https://data.gov.tw/license)，可修改、再散布，須顯名。
  取得臺中登記 240,604 筆，酒吧相關候選 192 筆；沒有來源座標，僅 21 筆符合保守篩選而進行門牌編碼。
- 環境部氣候變遷署，[Cool map涼適點點位 177893](https://data.gov.tw/dataset/177893)，
  [GIS_P_82 官方資料頁](https://data.moenv.gov.tw/dataset/detail/GIS_P_82)，
  2026-11-07 05:20:10 UTC，來源匯入時間 2026-10-13 18:20:36 臺灣時間。
  採[政府資料開放授權條款第1版](https://data.gov.tw/license)。
  官網公開預覽 API `https://data.moenv.gov.tw/api/frontstage/datastore.search`，
  resource_id 為 `8e0bda24-9d41-4e83-a54e-a19ecc2cb9c3`。
  完整取得 11,791 筆，臺中有 606 筆統一超商與 515 筆全家，直接使用開放資料中的座標及營業時間原文。
- 地理編碼為 [Nominatim](https://nominatim.openstreetmap.org/)，座標來自 OSM，採 ODbL-1.0。
  本輪正式快取查詢時間 2026-11-07 05:23:30–05:23:52 UTC，實際逐筆時間見報告。
  遵守[使用政策](https://operations.osmfoundation.org/policies/nominatim/)，單機單執行緒，
  User-Agent `BarHopping-dev/0.1 (student project)`，至少間隔 1.1 秒，完整結果快取。
  App 不呼叫此服務，腳本預設離線，不得將一次性 `--geocode` 模式排程。
- OSM 額外名稱查詢，2026-11-07 05:22:29 UTC，仍採 ODbL-1.0。
  查得 78 筆，49 筆已在目錄，另外 29 筆為額外名稱候選；
  額外集合未取得可確認的新酒吧。查詢時間、原文及資料庫時間見 `tools/catalog/report.json`。

候選、去重及實際新增：

| 類別 | 原有 | 新來源候選 | 與既有／保留項目重複 | 排除 | 實際新增 | 最後 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 酒吧 | 55 | 221 | 1 | 210 | 10 | 65 |
| 7-ELEVEN | 747 | 606 | 433 | 4 | 169 | 916 |
| 全家 | 507 | 515 | 375 | 4 | 136 | 643 |

酒吧 221 個候選包含稅籍 192 筆、OSM 額外名稱規則候選 29 筆。
不同來源同店名且距離 ≤150 公尺，或超商同品牌且距離 ≤60 公尺即合併，保留既有 OSM；
逐筆記錄保留 ID、名稱與距離。九族居酒屋距既有 OSM 點約 8 公尺，故保留 OSM。
8 筆超商同分店名但位置相距 150–1,000 公尺，無法判定是移店或座標錯誤，排除新資料待確認。
原有 OSM 不同 node/way 的疑似重複未刪除。

酒吧排除 210 筆：104 筆涉及 KTV、歌唱、舞場、夜店、旅館、理容、菸酒零售批發或製造；
67 筆雖登記飲酒店但無法由名稱確認對外酒吧；25 筆 OSM 零售、書櫃或型態不明；
4 筆沿用餐飲／咖啡／飲料 bar 排除規則；10 筆無唯一精確門牌結果。
原始 OSM 的 13 筆排除另保留在 `tools/osm/report.json`，不重算於這 210 筆。

地理編碼 21 筆有 11 筆唯一精確門牌結果，其中 1 筆為前述重複店家、10 筆新增。
另 10 筆只回傳路段或門牌／行政區不吻合的結果，未硬放進目錄。
排除店家為那一間居酒屋、共話餐酒館有限公司、炭吉日式居酒屋、亦品居酒屋福星店、
賣烤賣炒居酒屋、臺虎精釀股份有限公司台中門市、照燒日式居酒屋、嗑吧炸雞餐酒館、
喬町居酒屋、亦品居酒屋。

### 考慮但未匯入的來源

- 交通部觀光署，[餐飲－觀光資訊資料庫 7779](https://data.gov.tw/dataset/7779)，
  政府資料開放授權條款第1版，2026-11-07 05:19:50 UTC 下載。
  本次臺中 226 筆均沒有名稱符合現有酒吧關鍵字的候選，因此沒有匯入或使用其圖片、描述。
- [臺中市觀光活動、景點及店家清單 177990](https://data.gov.tw/dataset/177990) 的資源為 PDF 清單，
  本次未實作 PDF 匯入；可再查是否有適合機器處理且授權一致的資料版本。
- 財政部同份稅籍另找到統一超商名義 929 筆、全家名義 628 筆。
  這是登記數而非確認門市數，無座標且登記名稱未必有分店名，本輪不進行大批次地理編碼，
  不以公司名及推測座標補入超商。
- TGOS 地址定位服務可再確認申請方式及定位成果再散布條款，本輪沒有取得授權明確的可用憑證或結果，未使用。
- 7-ELEVEN／全家官方門市查詢的再散布授權未確認，只列為可再確認，未爬取。
  未使用 Google Maps、Instagram、Facebook、評論網站或美食網站資料。

### 其他品牌與限制

OSM 原始資料在服務範圍內可辨識萊爾富 162 筆、OK 59 筆，有座標、可依 ODbL 整理。
財政部稅籍另有萊爾富名義 177 筆、來來超商名義 0 筆，沒有座標，不能視為完整品牌門市數。
本輪 Cool Map 臺中資料未提供這兩品牌。
後續若要納入，需擴充 `ConvenienceBrand`、匯入品牌辨識、品牌選擇／圖示／篩選相關 UI 及測試，
並檢查 provider 的品牌集合；本工作未實作。

酒吧資料仍不完整。稅籍登記名可能不是招牌名，精確門牌也不代表已確認店面入口、樓層或目前仍營業。
為避免誤收，泛稱餐飲公司、同時登記零售的餐酒店及低精度編碼可能被保守排除。
Cool Map 是參與涼適點的門市快照，既非全品牌完整名單，也不保證最新狀態；
來源中的營業時間僅供參考。距離去重是啟發式，緊鄰分店可能誤合併，移店或大幅座標偏移也可能漏判。

政府來源新增顯名義務，**主代理需在 App 資料來源說明補上**
「財政部財政資訊中心（2026）全國營業(稅籍)登記資料集」與
「環境部氣候變遷署（2026）Cool map涼適點點位」，並提供政府資料開放授權條款第1版連結及聲明。
本輪依工作範圍未修改 UI，metadata 與報告皆標記 `appAttributionPending: true`。
保留 OSM／ODbL 標示，合併資料庫依 ODbL 要求提供，政府來源另保留顯名與原授權。

重跑、下載、快取與篩選詳見 [增補工具說明](../tools/catalog/README.md)。
完整新增／排除／重複清單、穩定來源 ID 與定位證據在 `tools/catalog/report.json`；
驗證與指定實機建置結果在 `tools/catalog/verification.json`。
