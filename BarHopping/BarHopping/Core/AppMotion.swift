import SwiftUI

/// 小範圍、可中斷的狀態動畫。請透過 appAnimation 或 withAppAnimation 尊重減少動態效果。
enum AppMotion {
    /// 選取底色、按鈕放開；不套在整個頁面或地圖鏡頭。
    static let tap: Animation = .snappy(duration: 0.18, extraBounce: 0)
    /// 卡片插入、錯誤說明、展開收合；不對長清單逐列錯開播放。
    static let reveal: Animation = .smooth(duration: 0.26, extraBounce: 0)
    /// 自訂浮層內的版面變更；系統 sheet 的呈現與拖曳仍交給系統。
    static let sheet: Animation = .smooth(duration: 0.32, extraBounce: 0)
    /// 單次完成回饋；不要循環播放，也不要用在數量、定位或錯誤上。
    static let emphasis: Animation = .spring(duration: 0.3, bounce: 0.12)

    /// 幾何改變在減少動態效果時直接更新，避免只有換曲線卻仍移動。
    static func resolved(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    enum Transition {
        /// 初次資料到達、短卡片顯示，垂直位移僅 8pt。
        case reveal
        /// 有穩定 ID 的清單插入／刪除；刪除僅淡出，不讓內容飛離畫面。
        case insertionRemoval
    }

    static func transition(_ kind: Transition, reduceMotion: Bool) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let entrance = AnyTransition.opacity.combined(with: .offset(y: 8))
        switch kind {
        case .reveal: return entrance
        case .insertionRemoval: return .asymmetric(insertion: entrance, removal: .opacity)
        }
    }
}

/// 在 View 讀取 accessibilityReduceMotion 後傳入；閉包只放同步 UI 狀態更新，不包網路等待。
/// 非同步完成後回到主執行緒再呼叫。減少動態效果時也抑制外層 transaction 的動畫。
@MainActor
func withAppAnimation<Result>(
    _ animation: Animation? = nil,
    reduceMotion: Bool,
    _ updates: () throws -> Result
) rethrows -> Result {
    var transaction = Transaction(animation: AppMotion.resolved(animation ?? AppMotion.reveal, reduceMotion: reduceMotion))
    transaction.disablesAnimations = reduceMotion
    return try withTransaction(transaction, updates)
}
