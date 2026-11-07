# BarHopping 首版規格與共用契約

狀態：供兩位 Agent 實作使用的規格草案。此階段只產出文件，不實作程式。

## 1. 產品目標

使用者選擇起點、數間酒吧及終點，建立沿實際步行道路行進的串店路線。使用者能調整站點順序，查看分段距離、步行時間與停留時間，並在裝置上儲存路線草稿。

「酒精路跑」首版以步行串店規劃為產品定義。交通模式固定為步行，時間顯示為步行估算，不推算飲酒後的運動能力。

## 2. 已知需求與暫定範圍

- 必須使用開放地圖資料，不使用 Apple MapKit、Apple Maps 地圖、搜尋或路由服務。
- 地圖、地點搜尋與路由各自使用可替換的介面。共用資料不可包含任何地圖 SDK 專屬型別。
- 首發平台尚未指定，本規格不指定 SwiftUI、React Native、Flutter 或 Web。平台確定後，Agent A 選用對應的 MapLibre 整合，API 不變。
- 暫以台北市作為首個服務範圍，介面使用繁體中文。實際支援區域由服務端配置並回傳地理邊界。
- 每條路線支援 1 至 8 間酒吧。起點與終點不計入酒吧數量。
- 支援單程與回到起點。每站停留時間預設 30 分鐘，可設定 0 至 180 的整數分鐘。
- 首版保留使用者指定順序。自動排序、依目標公里數產生路線與營業時間排程列入後續版本。
- 首版不含帳號、多人同步、訂位、付款、背景定位、語音導航、離線地圖及跨裝置分享。

以上城市、站數與停留時間為本次規格的預設值，不代表使用者已指定。

## 3. 地圖與資料方案

地圖資料採 OpenStreetMap。原生 iOS 與 Android 採 MapLibre Native，Web 採 MapLibre GL JS。MapLibre 負責繪製地圖，不負責產生路線。[MapLibre 專案說明](https://maplibre.org/)

路由預設採可自行部署的 Valhalla，使用 pedestrian 模式。服務端將其輸出轉成共用格式，不將供應商的編碼折線或錯誤直接交給客戶端。[Valhalla 路由文件](https://valhalla.github.io/valhalla/api/route/api-reference/)

底圖採 OSM 衍生的向量圖磚，style、圖磚、字型與圖示來源皆需可配置。實作交付須列出實際服務來源及各資產授權，正式環境可使用自架或明確允許 App 使用的供應商。開放資料不等於公共伺服器無限制免費使用，不能將 OSM 公共圖磚服務當成預設正式環境基礎設施。[OSM 圖磚政策](https://operations.osmfoundation.org/policies/tiles/)

地圖需持續顯示可點擊的 `© OpenStreetMap contributors`，連至授權頁；另顯示圖磚供應商要求的標示。資料來源、更新時間與授權清單由 Agent B 維護。[OSM 著作權與授權](https://www.openstreetmap.org/copyright)

酒吧目錄由服務端匯入區域 OSM 資料中的 `amenity=bar` 與 `amenity=pub`，保留來源識別碼。店名搜尋直接搜尋此目錄。首版不含一般地址搜尋，不依賴公共 Nominatim。OSM 缺店時，可由使用者在地圖上新增自訂站點，資料只保存在路線草稿。

## 4. 使用流程

### 底部分頁導覽

Tab bar 固定為五個分頁，由左至右依序為「首頁」、「地圖」、「路跑」、「團體」、「你」。標籤使用上述原文，不改為其他名稱。預設進入「首頁」。

以下分頁用途為暫定安排，除分頁名稱與順序外，細部內容仍可依後續需求調整。

- 首頁：提供開始規劃與繼續編輯草稿的入口。
- 地圖：瀏覽酒吧、搜尋地點及選擇路線站點。
- 路跑：編輯目前路線、調整站序、計算路線及查看已儲存路線。
- 團體：保留團體功能入口。建立團體、加入團體與多人同步的流程尚未定義，不因新增分頁就納入首版後端範圍。
- 你：提供本機設定與地圖資料來源說明。帳號與個人檔案功能尚未定義。

地圖與路跑共用同一份目前 RoutePlan，切換分頁不得清除草稿或建立另一份不一致的規劃。從路跑選擇「在地圖查看」時切換至地圖並呈現同一條路線。各分頁保留自己的導覽狀態，地圖另保留視角與搜尋條件。

### 路線規劃流程

1. 從首頁開始規劃，進入地圖，使用目前位置或地圖長按設定起點。拒絕定位仍可完成規劃。
2. 搜尋酒吧名稱或瀏覽目前地圖範圍的酒吧，查看店名與地址，再加入路線。
3. 自訂站點可由地圖長按新增，必須輸入名稱。
4. 選擇回到起點，或以地圖長按設定獨立終點。
5. 切換至路跑，在站點清單調整順序、刪除酒吧與修改停留時間。
6. 點選「計算路線」，顯示道路折線、站點編號、分段與總計。
7. 修改規劃後，舊結果標記為「路線需重新計算」。重新計算成功才移除此標記。
8. 儲存草稿後可關閉並重新開啟。恢復的結果標記為「已儲存的估算」，可重新計算。

## 5. 共用資料定義 v1

以下為資料契約，不是任何語言的程式碼。必要欄位除特別註記外不可為空。

- `Coordinate`：`latitude` 與 `longitude`，WGS84 十進位數。緯度介於 -90 至 90，經度介於 -180 至 180。
- `Place`：`id`、`name`、`coordinate`、`category`、`address`、`openingHoursText`、`source`、`sourceId`、`updatedAt`。category 為 bar 或 pub；地址與營業時間未知時為 null。source 為 osm，sourceId 包含 OSM 元素種類及 ID。openingHoursText 僅供參考，首版不判斷目前是否營業。
- `Waypoint`：`id`、`name`、`coordinate`、`placeId`。自訂站點的 placeId 為 null。id 是此次規劃內唯一的識別碼，不隨拖曳排序改變。
- `Stop`：`waypoint` 與 `dwellMinutes`。相同 placeId 不可加入兩次；自訂站點與既有起終點可在同一座標。
- `RoutePlan`：`schemaVersion=1`、`id`、`title`、`origin`、`stops`、`endMode`、`destination`、`updatedAt`。endMode 為 returnToOrigin 或 custom；前者 destination 必須為 null，後者必須提供 Waypoint。
- `RouteRequest`：`clientRequestId`、`plan`、`profile=walking`。clientRequestId 每次計算皆不同，成功及失敗回應均須回傳。
- `RouteLeg`：`fromWaypointId`、`toWaypointId`、`distanceMeters`、`walkingDurationSeconds`、`geometry`、`snappedFrom`、`snappedTo`。snapped 欄位為實際配對到路網的 Coordinate。
- `RouteResult`：`clientRequestId`、`planId`、`legs`、`distanceMeters`、`walkingDurationSeconds`、`dwellDurationSeconds`、`totalDurationSeconds`、`warnings`、`computedAt`、`routingDataUpdatedAt`。
- `ServiceError`：`clientRequestId`、`code`、`message`、`retryable`、`waypointIds`。非路由請求的 clientRequestId 可為 null。無特定問題站點時 waypointIds 為空陣列。

距離一律為公尺，時間一律為秒，日期一律為含 UTC 時區的 ISO 8601 字串。GeoJSON geometry 使用 WGS84 LineString，陣列順序為 `[longitude, latitude]`。一般 Coordinate 物件使用具名欄位，禁止用不具名二元素陣列。

## 6. HTTP API v1

Agent B 擁有 API 文件與回應範例。Agent A 使用相同契約建立 mock，不直接呼叫 Valhalla 或外部地點服務。

- `GET /v1/config`：回傳 `serviceArea` 的 GeoJSON Polygon、`maxStops=8`、`mapStyleUrl`、`attributions`、`placeDataUpdatedAt`。attributions 每項包含 text 與 url。地圖來源不得包含需保密的伺服器金鑰。
- `GET /v1/places?bbox=west,south,east,north&q=店名&limit=50&cursor=...`：bbox 必填，q 可省略，limit 為 1 至 100。回傳 `items` 與可為 null 的 `nextCursor`。q 搜尋範圍內的店名，不做地址解析。游標不透明，資料按 id 穩定排序。
- `GET /v1/places/{id}`：回傳 Place；不存在時回傳 HTTP 404 與 PLACE_NOT_FOUND。
- `POST /v1/routes/preview`：輸入 RouteRequest，成功回傳 HTTP 200 與 RouteResult。不建立服務端儲存記錄。

共同錯誤碼：INVALID_REQUEST 對應 HTTP 400、OUTSIDE_SERVICE_AREA 與 NO_WALKABLE_ROUTE 對應 422、PLACE_NOT_FOUND 對應 404、RATE_LIMITED 對應 429、UPSTREAM_UNAVAILABLE 對應 503、UPSTREAM_TIMEOUT 對應 504。429 須提供 Retry-After。輸入非法時不得呼叫路由引擎。只有 429、503、504 的 retryable 為 true，首版由使用者手動重試。

服務端路由上游逾時為 15 秒，客戶端請求逾時為 20 秒。這是實作設定，不是已測得的效能。

## 7. 路線計算規則

- 單程依 origin、使用者指定順序的 stops、destination 計算。回到起點時最後一點為 origin。
- N 間酒吧必須回傳 N+1 個 legs。相同座標的相鄰點回傳距離與時間皆為零的 leg，仍保留兩個相同座標的 LineString。
- 各站作為可停留的路由斷點，不能只作為折線經過點。路線需使用步行路網及其通行限制，不得以汽車路線或直線替代。
- 每個站點與路網配對距離不得超過 100 公尺。超過則回傳 NO_WALKABLE_ROUTE 並指出 waypointIds。前端保留原始圖釘並顯示路網配對點，避免把配對點誤認為店家入口。
- 任一段無路可走，整次計算失敗，不回傳看似完整的部分路線。
- 總距離等於 legs 距離總和。步行時間等於 legs 步行時間總和。停留時間等於 stops 的 dwellMinutes 總和乘以 60。總時間為步行時間加停留時間。
- warnings 為文字陣列。所有結果皆包含「路線依地圖資料估算，未確認即時封路與店家營業狀態」。
- 結果不宣稱為安全路線、無障礙路線或全域最短路線。

## 8. 分工與整合責任

Agent A 擁有五分頁導覽、客戶端地圖、規劃操作、結果顯示、本機草稿與 mock。Agent B 擁有地點資料、API、步行路由、服務設定與資料來源文件。兩者不得各自定義不同的 RoutePlan。團體與帳號 API 仍待功能規格確定，不包含在 Agent B 目前任務。

Agent B 先交付 API 契約與固定範例，Agent A 可立即用範例開發。整合時先驗證搜尋與座標順序，再驗證路線與錯誤狀態。契約變更先更新本文件及範例，雙方同步後才修改實作。

首發平台由專案擁有者在實作開始前指定；本次文件工作不建立應用程式骨架，也不預設 iOS 專屬架構。

## 9. 整體完成標準

- Tab bar 由左至右為首頁、地圖、路跑、團體、你。地圖與路跑來回切換後，站點、順序與目前路線一致。
- 使用同一組起點、三間酒吧與終點，能搜尋、加入、排序、計算及儲存恢復。
- 回到起點的路線包含最後一段返回道路。
- 修改站點後不會把舊結果顯示成最新結果。較晚抵達的舊請求不會覆蓋新規劃。
- 拒絕定位、搜尋無結果、路由不可達、上游逾時與底圖失敗皆可看見狀態並繼續編輯。
- 實際路由整合至少驗證一組道路或河岸繞行案例，證明結果不是站點間直線連接。
- 共用模型及 API 不依賴 MapKit，程式與設定不包含 Apple Maps 地圖、搜尋或路由呼叫。
- 地圖授權標示可見，交付文件列出圖磚、資料、路由服務與啟動方式。
