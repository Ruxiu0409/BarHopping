# BarHopping 動畫盤點與下一輪分工

盤點日期：2026-11-07。只讀來源，這輪僅新增 Core 動畫檔與本文，尚未套用至現有畫面。其他 agent 正在改畫面，以下行號是本輪讀取時的定位，下一輪請以相鄰符號重新搜尋。這是程式碼盤點，未使用模擬器或宣稱已完成實機視覺驗收。

所有 Swift 路徑以 `BarHopping/BarHopping/` 為根目錄。P0 為最常走的操作，P1 為後續狀態回饋，P2 為低頻細節。每組按優先順序排列，可分給 Map、Run、Home、Groups／Profile／SafeRide／ContentView 四位 agent。

## 設計原則與共用 API

依據 [Apple HIG Motion](https://developer.apple.com/design/human-interface-guidelines/motion) 與 [accessibilityReduceMotion](https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion)：用動畫交代操作結果、內容關係與等待狀態；保留系統原有行為；讓動態可減少。下列參數是本專案的設計選擇，並非 Apple 規定的秒數。

- `AppMotion.tap`：0.18 秒 snappy，選取與按鈕放開。`reveal`：0.26 秒 smooth，小卡片與說明出現。`sheet`：0.32 秒 smooth，只用在自訂浮層內版面。`emphasis`：0.3 秒、少量 bounce，只做單次完成回饋。
- `.appAnimation(AppMotion.reveal, value: state)` 會自動讀取減少動態效果；只包最小變動容器。不要以整個 PlannerStore、整份表單或 TabView 作動畫範圍。
- `withAppAnimation(AppMotion.reveal, reduceMotion: reduceMotion) { ... }` 用在 View 的同步狀態更新；呼叫端先讀 `@Environment(\.accessibilityReduceMotion)`。不要把 `await` 或網路工作包進去，也不要讓 Store 持有 SwiftUI 動畫設定。
- `.appTransition(.reveal)` 為 opacity 加 8pt 位移；`.insertionRemoval` 插入同上、移除淡出。必須搭配父層 `.appAnimation(value:)` 或狀態更新的 `withAppAnimation` 才會播放。對既有內容替換，先決定 identity 是否真的應該改變；不要對整頁 `.id(...)` 以強制重建。
- `.buttonStyle(AppPressableButtonStyle())`：自繪卡片或 chip 按下立即縮至 98% 並變淡，放開短彈回；不延遲 action。不要套原生 `.bordered`、toolbar、Menu、Stepper、Toggle 或整張含多個操作的卡片。
- `.appNumericText(value: count)`：在 Text 上顯示數值變化，自帶 `.contentTransition(.numericText())` 與動畫。`value` 用原始數值，避免任意格式文字觸發動畫。額度遞減可傳 `countsDown: true`。
- `.appSymbolReplacement(value: isSelected)`：同一個 SF Symbol 的狀態替換。`.appSymbolBounce(trigger: successSequence)`：單次完成圖示，只套 Image，不讓整張卡片 bounce。同一圖示擇一，避免疊加。
- `.appLoadingPlaceholder(isLoading)`：只用少數可見卡片的固定版面，redacted 加低對比 shimmer。外層另放可讀的 `ProgressView("載入中")`，骨架本身不接受操作且對 VoiceOver 隱藏。不要為展示 shimmer 人為延長等待。
- 觸覺直接用系統 `.sensoryFeedback`，不另建震動引擎。`.selection` 用實際選取改變；`.success` 用儲存／送出確實成功的事件序號；`.error` 用使用者操作失敗的事件序號。同一個錯誤再次失敗也應更新序號，重繪、初次載入與背景刷新不得觸發。成功與錯誤仍必須有可讀文字，不能只靠動畫或觸覺。

減少動態效果開啟時，`appAnimation` 與 `withAppAnimation` 採無動畫並抑制外層 transaction；transition 降為 opacity，配合上述 helper 時直接更新；按壓保留即時透明度、取消縮放；數字取消滾動；SF Symbols 取消 bounce／replace；placeholder 靜態。App 非前景時不建立 shimmer 時間線。不要將這些 modifier 套在需要保留系統動畫的整個導覽容器。

可在 `Core/AppMotionPreview.swift` 的一般／減少動態效果兩個 `#Preview` 檢查示例。第二個 Preview 使用自訂可寫的 `.environment(\.appReduceMotion, true)`，不覆寫唯讀的系統環境值。所有 helper 都取系統設定與此值的 OR，因此無法關閉系統已啟用的減少動態效果；`withAppAnimation` 的呼叫端也應傳入兩者的 OR。本輪未啟動 Preview，以免帶起模擬器。

配色沿用共用主題：實心按鈕與選中填色使用 `AppTheme.accent`，深色底上的文字連結、小圖示與細線使用 `AppTheme.accentOnDark`，不另外定義動畫專用主色。

## Map 組

1. **P0：選取卡片、結果列表展開與換店。** `Map/MapTabView.swift:77` 已有三個根層 `.snappy`，`:312` 與 `:319` 已有整塊 move transition，所以不是完全沒有動畫；目前未讀減少動態效果，長距離移入也過強。改為底部小容器 `.appAnimation(AppMotion.sheet, value: screen.selection)`／`listExpanded`，子項 `.appTransition()`。換不同店但沿用同類型卡片時，先確認是否需以 place ID 區分 identity；不要重建 MapLibre view。快速點 A、B、關閉應直接朝最新狀態銜接，不能排隊。
2. **P0：加入路線的按壓與結果。** `Map/MapCards.swift:38`、`Map/ConvenienceStoreCard.swift:30`、`Map/MapTabView.swift:335`。自繪加入按鈕缺少按壓縮放；加入後標籤／勾號直接切換。加 `AppPressableButtonStyle`，文字用局部 `tap`，SF Symbol 用 `appSymbolReplacement`。只在 `planner.addStop` 回傳成功後觸發一次 `.success`；重複加入／超過上限顯示既有錯誤並觸發 `.error`，不能在每次點擊先宣告成功。
3. **P0：篩選 chip 與上方額外控制。** `Map/MapTabView.swift:159`、`:176`、`:204`。分類、超商品牌、熱門開關的描邊／顏色瞬間變，超商控制與熱門說明突然擠開版面。chip 用按壓 style，選取背景局部 `tap` 與 `.selection`；新增控制區用 `appTransition()` 加 `reveal`。不可把動畫沿 state 傳入 map render model，讓全部圖釘一起做縮放。
4. **P1：搜尋、錯誤與 toast。** `Map/MapTabView.swift:60`、`:131`、`:221`；`Map/MapCards.swift:279`、`:309`。toast 有 transition、移除有預設 `withAnimation`，但出現未必進入動畫 transaction；底圖／定位錯誤沒有對應過場。將進出統一成局部 `appAnimation` 和 `appTransition`，沿用取消舊 task 的邏輯。搜尋進度與清除按鈕預留等寬位置淡換，載入／無結果／失敗交替只切換狀態容器，保留上一次可用結果。首次載入可用 2–3 列 `appLoadingPlaceholder`，分頁追加保留底部 ProgressView，不重播全部結果。
5. **P1：摘要、站數與路線計算狀態。** `Map/MapCards.swift:124`、`:134`、`:155`、`:197`；`Map/MapTabView.swift:321`。摘要卡首次加入站點後突然出現，計算中／結果／失敗的高度與標籤直接變，站數缺少 numeric transition。卡片用 `.insertionRemoval`，狀態用 `reveal`，數字用 `appNumericText`。請保留缺條件與舊估算文字，不能讓淡出延遲錯誤或呈現過時結果為成功。

鏡頭另有必要的無障礙修正：`Map/MapLibreMapView.swift:332` 的 `applyPendingCommand()` 在 `:339`、`:341`、`:351`、`:363` 已使用 MapLibre `animated: true`。不要再疊 SwiftUI camera animation；下一輪由 Map 組將減少動態效果傳到 UIViewRepresentable／Coordinator，改用 SDK 的 `animated: false`。此屬 SDK 邊界，`appAnimation` 無法代替。地圖手勢跟手、viewport 回報、overlayInsets 幾何量測、圖層批次資料更新都不做逐幀 spring。`Map/MapCards.swift:372` 圖資授權標示必須一直可見，不用過場隱藏。

## Run 組

1. **P0：站點上下移、刪除、空清單與站數。** `Run/RunTabView.swift:296`、`:315`、`:319`、`:323`、`:332`；`Run/RunStopRow.swift:18`、`:51`。自訂上下移／刪除沒有明確動畫 transaction，空白提示與列內容直接跳換。保留 waypoint 穩定 ID，以 `withAppAnimation(reveal)` 包 UI 發起的同步更新，或在站點容器追蹤 `plan.stops.map(\.id)`；插刪用 `.insertionRemoval`。站數、編號與停留分鐘 Text 用 `appNumericText`。List 原生拖曳與 swipe delete 保留系統動畫，不額外疊位移，也不替 bordered 操作按鈕換 style。
2. **P0：計算中、結果、過期與失敗。** `Run/RunTabView.swift:116`、`:150`、`:345`、`:46`；`Run/RunResultSection.swift:10`、`:17`、`:20`。條件 Section、計算按鈕／取消行與新結果直接替換；過期結果 opacity 突變。以狀態 enum／resultStatus 追蹤局部 `reveal`，結果列交給 List 的插入處理，數值 Text 用 `appNumericText`。stale 的文字／色彩立即反映真實狀態，再做短淡換；不可動畫插值路線資料或假裝計算百分比。成功／失敗只在請求完成時給一次觸覺，取消不發成功回饋。
3. **P0：開始與酒票入口。** `Run/RunStartButton.swift:11` 已有 medium impact，但 `.plain` 沒有自繪按壓回彈；`Run/DrinkPassBanner.swift:8` 同樣是自訂入口。套 `AppPressableButtonStyle`，保留 action 即時執行。開始只會跳地圖，不是真正完成路跑，請勿加慶祝動畫，也不要再加第二次 impact。跨分頁依 ContentView 原生行為處理。
4. **P1：儲存、toast 與草稿 sheet。** `Run/RunTabView.swift:419`、`:458`、`:483`；`Run/SavedDraftsView.swift:68`、`:106`、`:191`。toast 目前只有移除／手動關閉明確 `withAnimation`，進入未統一；儲存標籤和 spinner 直接換。局部 `tap` 與 `.appTransition()` 統一進出，沿用 task 取消避免舊 toast 刪除新 toast；保存成功給 `.success`，失敗給 `.error`。草稿讀取／空／錯誤只淡換內容容器，刪除成功後以穩定 draft ID 做 List 更新，不能在磁碟刪除成功前先動畫移除。sheet 本身不重做。
5. **P1：酒票方案、金額與示範票券。** `Run/DrinkPassDetailView.swift:55`、`:61`、`:63`、`:85`、`:148`；`Run/DrinkPassTicketView.swift:8`。方案選擇、數量、合計與新票出現目前未自訂動畫。合計拆出獨立 Text 用 `appNumericText(value: totalPrice)`，票券新增用 List 原生插入加 `reveal`，成功圖示可選單次 `appSymbolBounce` 和 `.success`。inline Picker／Stepper 自己的選取動作不重做；QR 圖與票號保持靜態，不加 shimmer、縮放、閃爍或逐字輸入。

## Home 組

1. **P0：規劃入口與最近草稿。** `Home/HomePlanSection.swift:14`、`:24`、`:33`、`:40`、`:47`。自繪 `.plain` 按鈕無按壓微動畫，繼續編輯／草稿／錯誤資訊條件區直接出現。入口按鈕用 `AppPressableButtonStyle`，資料到達追蹤 draft ID 清單與是否有目前路線，局部 `reveal` 加 `.insertionRemoval`。最多三張草稿可一起短淡入，不用一張一張延遲。從其他分頁回來不重新做入場表演。
2. **P0：論壇分類與載入／空白／錯誤／文章插入。** `Home/HomeTabView.swift:147`、`:159`、`:165`、`:172`；`Home/HomeTheme.swift:70`。HomeChip 顏色與篩選結果缺少局部動畫，初始 spinner 突然換文章，發文後列表直接增列。chip 用 `tap` 與 `.selection`；內容狀態用 `reveal`，新增貼文用穩定 post ID 與 `.insertionRemoval`。只在首次真實等待用少數 `appLoadingPlaceholder`，下拉刷新保留原內容與原生 refresh indicator；不要在整個 LazyVStack 對每個 post onAppear 做飛入。
3. **P0：文章讚數、圖示與留言。** `Home/ForumPostDetailView.swift:36`、`:44`、`:63`、`:69`、`:75`、`:118`；`Home/ForumPostRow.swift:27`。詳細頁已對 isLiked 做 `.selection`，不再疊加震動。將 heart 由 Label 分離為 Image 使用 `appSymbolReplacement`，讚數／留言數 Text 用 `appNumericText`。留言新增用 `.insertionRemoval` 和 `reveal`，空提示淡換；送出按鈕若維持自繪可加按壓 style。不要為了動畫延遲清空輸入、鍵盤關閉或強制捲到會遮住 VoiceOver 焦點的位置。
4. **P1：發文表單與酒譜。** `Home/ForumComposeView.swift:60` 已有 `$includesRecipe.animation()`，缺少統一參數與減少動態效果處理；`:104`、`:117`、`:122`、`:146`、`:151` 的材料／步驟增刪未明確給動畫。替換預設 binding animation 為 View 局部 `appAnimation(reveal, value: includesRecipe)`，增刪用穩定 UUID 與短 `withAppAnimation`。Form 列更新交由系統處理，不在 Form 上疊多重 transition。來源 HomeChip 加選取回饋；欄位每次打字、canPost 每次驗證都不震動。發布成功的回饋放在實際 `addPost` 完成處，不在 sheet 開啟／取消時發生。
5. **P1：通知、未讀點與任務。** `Home/HomeTabView.swift:92` 通知圖示直接替換；`Home/Notifications/NotificationsView.swift:23`、`:44` 與 `NotificationRow.swift:21` 未讀點直接消失。bell 用 `appSymbolReplacement`，未讀點 opacity 加局部 `tap`，全部已讀只給一次回饋，不逐列 bounce。`Home/HomePersonalSections.swift:50`、`:86`、`:89`、`:93` 的統計與任務目前來自 mock，靜態數字不用開場從零計數；未來有真實進度變更，再對 fraction 做 `reveal`、數值用 `appNumericText`，只有新完成時才用 `emphasis`／單次 success。每分鐘更新的相對時間保持靜態。

## Groups／Profile／SafeRide／ContentView 組

1. **P0：團體分類、標籤與加入結果。** `Groups/GroupsTabView.swift:19`、`:23`、`:96`、`:117`、`:122`、`:140`。segment 下方整區、探索標籤勾號、加入／已加入與數量目前直接變。segment 保留原生滑塊，只對內容局部 `reveal`；自繪標籤用按壓 style、`tap`、`.selection`；加入後用 `appSymbolReplacement` 與成功事件觸覺。清單追蹤 group ID，沒有資料時用 `.appTransition()`，不可對切換整頁做左右滑入造成方向歧義。
2. **P1：團體詳情、活動參加與留言。** `Groups/GroupDetailView.swift:67`、`:111`、`:134`、`:160`、`:179`；`Groups/GroupEventDetailView.swift:28`、`:30`。加入後的成員功能、活動／留言新增與參加人數缺少過場。成員功能用 `reveal`，新項目用 `.insertionRemoval`，人數用 `appNumericText`，參加勾號用 `appSymbolReplacement` 與 `.selection`。`:134` 的 DisclosureGroup 已有原生開合，不再加旋轉箭頭或第二套高度動畫；退出後 dismiss 保留導覽系統處理。
3. **P1：你、頭像與核銷額度。** `Profile/ProfileTabView.swift:67`、`:153`、`:157`、`:161`、`:315`、`:413`。頭像與選取框直接替換，核銷進度與額度直接變。自繪頭像選擇卡／換酒碼按鈕加按壓 style；選頭像給 `.selection`，頭像只淡換，不讓所有分頁 icon bounce。額度用 `appNumericText(countsDown: true)`，ProgressView 值用局部 `reveal`；實際兌換成功後給一次 `.success`。核銷 sheet 關閉和 success alert 不疊第二個全頁過場。`:223` 的徽章目前 hard-code，不做假解鎖或每次回來重新彈跳。
4. **P1：安全回家定位與配對。** `SafeRide/SafeRideSheet.swift:151` 定位中／成功／失敗直接換，`:100` 的服務商卡為 `.plain`。定位狀態容器淡換，保留可見重試操作與系統 spinner；服務商卡用按壓 style，但開啟外部 App／電話不播放成功慶祝，因為尚未代表叫車成功。`SafeRide/SafeRideDemoView.swift:39`、`:62`、`:87`、`:114`、`:189` 的 estimate／matching／matched／cancelled 目前硬切。switch 各內容 `.appTransition()`，父層追蹤 stage 用 `reveal`，成功配對示範圖示單次 bounce、觸覺在 stage 真正成為 matched 時觸發。估價用 `appNumericText(value: estimate.amount)`。保留 `.task(id: stage)` 的取消語義與輔助焦點，取消後不可讓舊 task 再跳回 matched；不要旋轉整張卡或假進度條。
5. **P1／P2：團體 sheet、全 App sheet 與分頁。** `Groups/CreateGroupSheet.swift:23`、`:36` 的公開說明／標籤勾號直接切換，分別用局部 `tap`／`appSymbolReplacement`。`Groups/JoinGroupSheet.swift:23`、`:50` 邀請錯誤突然插入，用 `reveal`＋`.appTransition()`；重試失敗才 `.error`，打字清除錯誤不震動。`Groups/CreateGroupEventSheet.swift:52` 建立成功只回饋一次，失敗 alert 保留系統呈現。`ContentView.swift:9` 使用原生 TabView，`:40` 為頭像圖示；分頁本身沒有客製動畫是合理選擇，不加整頁 spring、matchedGeometry 或 onAppear 入場。若日後需分頁選取觸覺，以 router.selectedTab 變更一次 `.selection` 即可，程式自動導向與使用者點擊需分辨，避免不必要的震動。

## Sheet 與原生動畫保留清單

- 首頁發文 `Home/HomeTabView.swift:105`、路跑草稿 `Run/RunTabView.swift:71`：已用 `.sheet`，由系統處理進出、互動取消、鍵盤與減少動態效果。AppMotion 只套內部資料更新。
- 團體建立／邀請 `Groups/GroupsTabView.swift:45`、建立活動 `Groups/GroupDetailView.swift:39`：同上；關閉後推入詳情應沿既有導覽路徑，不加手動 delay 配合假動畫。
- 頭像／核銷 `Profile/ProfileTabView.swift:40`、`:43`，detent 在 `:368`、`:448`：保留系統拖曳與高度變更。圖碼、條款、剩餘額度必須可穩定讀取。
- 安全回家 `SafeRide/SafeRideButton.swift:16`，示範頁 `SafeRide/SafeRideSheet.swift:39`：保留 sheet 與 navigation push；電話確認／失敗 alert 不抖動、不再包 withAnimation。
- 地圖長按確認與自訂站點 `Map/MapTabView.swift:65`、`:69`，以及各處 confirmationDialog、alert、Menu、ShareLink、DatePicker、原生 Picker／Toggle／Stepper：保留系統呈現。不要因為未看到自訂 `.animation` 就當作缺少動畫。

## 下一輪驗收

1. 一般模式快速連續選店、篩選、加刪站點、上下移、送留言、取消配對；操作立即生效，動畫朝最新狀態銜接，不以 delay 或 completion 作業務邏輯的必要條件。
2. 開啟減少動態效果後重做相同流程；沒有位移、縮放、數字翻動、symbol bounce 或 shimmer，地圖 SDK 鏡頭也不飛行；文字、錯誤與選取狀態仍清楚。
3. 長列表捲動不反覆入場；刷新不清空現有內容；背景／離開畫面不持續執行 shimmer；無全螢幕重繪造成的地圖重建。
4. 用 VoiceOver 與輔助字級檢查焦點與訊息。placeholder 有獨立載入狀態，錯誤不僅靠顏色或震動，焦點不在動畫後跳到錯誤位置。系統導覽、sheet 互動關閉、鍵盤與拖曳排序仍可中斷。
5. 使用指定實機 destination 編譯，不安裝手機、不啟動模擬器；來源仍在平行修改時，先重新核對本文行號與是否已由另一位 agent 套用。

本輪編譯確認：使用 `xcodebuild -project BarHopping.xcodeproj -scheme BarHopping -destination 'id=00008150-001075642287801C' -allowProvisioningUpdates -derivedDataPath /tmp/bh-dd-motion build` 得到 `BUILD SUCCEEDED`。未安裝至手機，未進行動畫視覺驗收；建置資料夾完成後清除。
