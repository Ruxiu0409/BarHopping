# 安全回家

整合入口不需要參數，也不需要注入 PlannerStore。

```swift
SafeRideButton()

// 或由呼叫端管理呈現狀態
.sheet(isPresented: $showingSafeRide) {
    SafeRideSheet()
}
```

開啟 sheet 才透過現有 `LocationProvider` 請求前景單次定位，逾時使用該型別的 12 秒設定。起點固定為目前位置，不讀取路線最後一站。定位失敗可前往設定或重試，所有外部服務仍能開啟。從設定返回且先前定位失敗時會重試。

## 外部服務查證

2026-11-07 以 Apple iTunes Search API 查詢 `country=tw&entity=software`，再以 Lookup API 核對下列乘客端 ID、名稱與開發者。

- 台灣代駕 TWDD：`1003660128`，RICH INTERNATIONAL Co., Ltd.，[App Store](https://apps.apple.com/tw/app/id1003660128)。
- 55688 台灣大車隊：`579255069`，Taiwan Intelligent Life Co., Ltd.，[App Store](https://apps.apple.com/tw/app/id579255069)。
- LINE GO：`1538897906`，JDW CO., LTD.，為 LINE TAXI 搜尋結果中的乘客端，[App Store](https://apps.apple.com/tw/app/id1538897906)。
- yoxi：`1521393667`，Hotai Connected Co., Ltd.，[App Store](https://apps.apple.com/tw/app/id1521393667)。
- Uber 優步：`368677368`，Uber Technologies, Inc.，[App Store](https://apps.apple.com/tw/app/id368677368)。

可重現查詢：

```sh
curl 'https://itunes.apple.com/search?term=55688&country=tw&entity=software'
curl 'https://itunes.apple.com/lookup?id=1003660128,579255069,1538897906,1521393667,368677368&country=tw'
```

Uber 使用 `https://m.uber.com/ul/?action=setPickup` 搭配 URLQueryItem 編碼。目前位置有效時帶入 pickup 座標，未取得時使用 `pickup=my_location`。文字目的地僅傳 nickname，沒有地址解析；服務端是否採用該文字須以 Uber 畫面為準。Launcher 也支援在有目的地 Waypoint 時產生完整 dropoff 座標參數。

[使用者提供的 Uber 文件](https://developer.uber.com/docs/deep-linking-action-setpickup) 目前會轉至[新版 Deep Links 文件](https://developer.uber.com/docs/riders/ride-requests/tutorials/deep-links/introduction)，仍說明目前位置參數、座標參數與 universal link 行為，但新版推薦的路徑為 `/looking`。此功能沿用需求指定的 `/ul/` 格式；真機開啟與帶入效果尚需整合後驗證。未安裝 Uber 時由 Uber 控制導向網頁或商店，不保證一定停在網頁。

其餘服務只開台灣區 App Store HTTPS 頁面，不使用未公開的私有 scheme。55688 電話叫車另有獨立入口，[官方叫車方式](https://www.55688taxi.com/55688apptaxi)列有手機直撥 55688。55688、110、119 均先顯示確認，再由 `openURL` 開啟 `tel:`。

## 示範流程

選擇台中範例目的地，以目前位置到該範例的球面直線距離估價。公式為 NT$350 加每公里 NT$30，總額無條件進位至元。文字目的地保留為備註，並明示未解析地址。沒有定位時顯示「無法估價（未取得位置）」，仍可體驗模擬配對。

送出後顯示「配對司機中…」2.5 秒，再顯示虛構司機、評分、遮蔽車牌及示範抵達時間。配對中或配對完成均可取消，離開畫面會取消延遲工作。整段流程持續標示「示範模式，未實際叫車」，不呼叫任何派車 API。

一般字級的安全提醒固定於底部；輔助使用字級將完整提醒與電話移入可捲動內容，以免佔滿小螢幕。所有字體使用 Dynamic Type 語意字級，服務商、座標、估價與配對狀態提供 VoiceOver 文字。

## 整合注意

本次只新增 `SafeRide/`，沒有接入 Profile 或其他分頁。主代理可直接放入 `SafeRideButton()`，或呈現 `SafeRideSheet()`。

現有 Info.plist 產生設定已包含定位權限用途字串，內容目前只提到地圖與路線起點。主代理可將用途敘述擴充至「安全回家」；本次依分工未修改專案設定。

`#Preview` 包含主入口、輔助字級、示範估價與虛構司機狀態。外部 App 跳轉、電話與定位權限須在真機另行驗證。

## 本次驗證

依指定指令進行完整編譯與最終增量編譯，兩次均為 `BUILD SUCCEEDED`，`SafeRide/` 無編譯錯誤。`#Preview` 程式碼已通過編譯，未執行視覺預覽或截圖。未建立模擬器；完成後已清除 `/tmp/bh-dd-saferide` 建置產物。
