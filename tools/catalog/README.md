# 臺中地點增補工具

Python 3.9 以上，僅用標準函式庫。從專案根目錄執行。

```sh
# 首次建立或只補下載缺少的來源快照
python3 tools/catalog/download_sources.py
# 若 OSM 基礎快取尚不存在，先建立它；此步會覆寫 App 內附資料
python3 tools/osm/fetch_taichung.py
# 離線合併；只讀已有的地理編碼快取，不會發送地理編碼請求
python3 tools/catalog/expand_taichung.py
```

重新下載來源時執行 `python3 tools/catalog/download_sources.py --refresh`。
OSM 原始目錄要更新時另外執行 `python3 tools/osm/fetch_taichung.py --refresh`，
最後務必再執行增補合併，否則資料會回到只有 OSM 的版本。
服務範圍沿用 OSM 工具產生的 Polygon，增補工具不修改邊界。

財政部 ZIP 約 66 MB，直接串流解壓讀取 CSV，不落地展開整份全國 CSV。
`raw/` 包含原始來源快照、下載時間、網址與 SHA-256；`geocoding-cache/`
包含每次查詢參數、時間及完整結果，兩者均忽略 Git。
原始 OSM 快取仍位於 `tools/osm/raw/`。
不要同時執行多份下載／編碼／合併工作。
離線重建需要保留本次地理編碼快取；缺少必要快取會停止，不會寫出縮水的目錄。
全新環境沒有快取時，須先閱讀下列政策，再明確決定是否執行一次性編碼。

## 一次性地理編碼

只有確定新增候選需要地理編碼時，才手動執行：

```sh
python3 tools/catalog/expand_taichung.py --geocode
```

使用 [Nominatim 官方政策](https://operations.osmfoundation.org/policies/nominatim/)。
這是單機、單執行緒、一次性小批次，User-Agent 為
`BarHopping-dev/0.1 (student project)`，請求起始時間至少間隔 1.1 秒，
完整結果包含失敗與低精度結果均快取。HTTP 錯誤會停止，不會重試轟炸服務。
**不可將 `--geocode` 排程或反覆用於定期更新**。定期或超過一天的工作須依政策
降至每分鐘四次，或改用自架／另行取得授權的服務；目前腳本僅支援一次性模式。
App 不呼叫 Nominatim。不可刪除快取後再重複請求同一批資料。

只接受唯一一筆 `place_rank=30`、含門牌且城市、行政區、道路與完整門牌均吻合的結果。
路段中心、行政區中心、鄰近門牌、多門牌及無法解析的地址不納入。
目前精確到門牌不代表確認入口、店家仍營業或店面樓層。

## 來源與合併規則

- 財政部財政資訊中心「全國營業(稅籍)登記資料集」：
  https://data.gov.tw/dataset/9400 。政府資料開放授權條款第1版。
  酒吧候選為任一行業代號 `563114` 或名稱符合既有酒吧關鍵字。
  進一步要求店名具酒吧／酒館／餐酒／飲酒店等證據，並有餐飲行業。
  任一行業或名稱涉及 KTV、視聽、歌唱、舞場、夜店、旅館、理容、菸酒零售／批發、
  製造、雪茄則保守排除。登記名不等於招牌名，因此不匯入只有泛稱公司名的飲酒店。
- 環境部氣候變遷署「Cool map涼適點點位」：
  https://data.gov.tw/dataset/177893 。政府資料開放授權條款第1版。
  使用官網公開資料預覽介面的完整 `GIS_P_82` 資料；驗證 records 數與 total 相等。
  目前下載網址的共用 v2 API key 回覆每日額度已滿，因此使用官方網站同樣提供給
  未登入使用者的 `api/frontstage/datastore.search`，沒有使用帳號、私人 key 或繞過驗證。
  介面或 resource_id 若變更須更新下載腳本，不以空資料覆寫結果。
  只取臺中、`coolingtype` 為統一超商或全家便利商店者，直接使用來源座標與營業時間原文。
- 交通部觀光署「餐飲－觀光資訊資料庫」：
  https://data.gov.tw/dataset/7779 。政府資料開放授權條款第1版。
  下載後檢查 226 筆臺中餐飲資料，沒有名稱符合既有酒吧關鍵字的候選，因此未匯入。
- OSM 擴充名稱查詢：ODbL-1.0，Overpass API，原始查詢存於
  `tools/osm/raw/expanded-request.json`。延用既有名稱／排除條件，另要求餐飲標籤，
  零售、辦公、旅宿、書櫃及型態不明的建築名稱不作酒吧證據。本次無新增。

保留原有 OSM 資料。新來源與先前保留項目比較，同品牌距離 ≤60 公尺，或同類且名稱
相近、距離 ≤150 公尺即合併，保留既有項目並記錄 ID、距離與理由。
名稱相近使用 NFKC、品牌／分店後綴正規化、包含關係或字串相似度 ≥0.8。
同分店名相距 150–1,000 公尺的超商視為座標衝突，保留原資料並排除待確認。
來源內也套用相同規則，OSM 原本不同 node/way 的疑似重複不在此輪刪除。
所有新增點須在既有服務範圍內。

ID 為 `mof-tax-<統編>`、`moenv-coolmap-<recordid>`；sourceId 分別為
`9400/<統編>`、`GIS_P_82/<recordid>`，不依名稱或座標產生。
酒吧 category 維持 bar/pub，超商維持 7-ELEVEN／全家。
稅籍酒吧的 updatedAt 為此次來源取得時間，不宣稱為商家異動時間。
metadata 的 placeDataUpdatedAt 是合併目錄最新來源取得時間；
原始 OSM 資料庫時間另存 osmPlaceDataUpdatedAt，各來源時間另列 sources。

## 輸出與檢查

覆寫兩份地點 JSON、`taichung-data-metadata.json`、本目錄 `report.json`，
並在 `tools/osm/report.json` 增加 mergedCatalog 連結，保留其原始 OSM 統計。
報告逐筆列新增、重複、排除與地理編碼證據；`verification.json` 記錄這次驗證。

本次離線重跑後，再以專案實際 Swift 模型與 JSONCoding 解碼成功。
合併內含唯一 ID、合法品牌與所有點位在服務範圍內的斷言。
來源採快照，不保證完整或仍營業，Cool Map 也只涵蓋參與的涼適門市。

## App 顯名責任

政府資料授權條款：https://data.gov.tw/license 。
新增資料需要在 App 的資料來源說明中顯示以下資訊，**本工作未改 UI**，
正式再散布前須由主代理補齊；metadata/report 的 appAttributionPending 為 true。

- 財政部財政資訊中心（2026）全國營業(稅籍)登記資料集。
- 環境部氣候變遷署（2026）Cool map涼適點點位。
- 此開放資料依政府資料開放授權條款第1版提供，得於遵守條款下利用。
- 保留 © OpenStreetMap contributors 與 ODbL 來源標示；地理編碼也來自 OSM。

合併資料庫繼續依 ODbL 要求提供來源與衍生資料；政府來源另保留上述顯名與授權。
程式碼授權不受影響。

可重跑完整資料檢查：

```sh
python3 tools/catalog/verify_catalog.py
```

此檢查會離線重建並比對輸出 SHA-256，確認 OSM 原筆資料完全保留、欄位不變、
座標在界內、品牌合法、候選數帳目吻合、編碼快取存在，以及原始下載雜湊。
`verification.json` 另記錄使用實際 Swift 模型解碼及實機建置的此次結果；
日後只跑 Python 檢查不等於重新完成 Swift 解碼或 Xcode 建置。
