# Google Places 店家照片與資訊設定

本 App 會將每間店的照片網址、照片署名、電話、網站與簡介存入 `Place` 的選填欄位。啟用 Google Places SDK 後，將以店名與座標查找店家，讀取照片和店家詳情；顯示照片時需保留 SDK 回傳的署名。

## 建立受限制的 iOS key

1. 前往 [Google Maps Platform](https://console.cloud.google.com/google/maps-apis)，建立或選取一個有啟用帳務的專案。
2. 啟用 **Places SDK for iOS**。本 App 只需要這項產品；地圖底圖仍使用 MapLibre。
3. 在「APIs & Services → Credentials」建立 API key。
4. 在 Application restrictions 選 **iOS apps**，新增 bundle ID：`com.ruxiu0409.BarHopping`。
5. 在 API restrictions 選 **Restrict key**，只勾選 **Places SDK for iOS**。

## 安全放入本機專案

1. 複製 `BarHopping/Configuration/GooglePlacesSecrets.xcconfig.example` 為同資料夾內的 `GooglePlacesSecrets.xcconfig`。
2. 將 `YOUR_GOOGLE_PLACES_API_KEY` 改成新 key。該檔已被 `.gitignore` 排除。
3. 重新開啟專案。這個設定檔已經是 Debug、Release 的 Base Configuration，key 會在編譯時自動寫入 App 的 Info.plist。

完成後告訴 Codex，我會加入官方 Google Places SDK、查詢與快取邏輯，讓每一張地圖店家卡片顯示照片和最新可取得的資料。
