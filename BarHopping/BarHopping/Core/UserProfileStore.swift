import SwiftUI
import Observation

/// 預設的微醺風格頭像選項
struct AvatarPreset: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let color: Color
}

@MainActor
@Observable
final class UserProfileStore {
    var nickname: String = "阿凱"
    var levelTitle: String = "逢甲夜生活探索家"
    var selectedPresetId: String? = nil
    var customAvatarImage: Image? = nil

    // 通票資料
    var passName: String = "逢甲微醺 4 店跑吧通行證"
    var passTotalDrinks: Int = 4
    var passRedeemedDrinks: Int = 2
    var passCode: String = "BH-7749"
    var passActive: Bool = true

    var remainingDrinks: Int {
        max(0, passTotalDrinks - passRedeemedDrinks)
    }

    // 統計資料
    var visitedBarsCount: Int = 6
    var totalWalkingKm: Double = 4.2
    var soberScore: String = "微醺愉快"

    // 預設頭像選項
    static let presets: [AvatarPreset] = [
        AvatarPreset(id: "martini", name: "微醺馬丁尼", systemImage: "wineglass.fill", color: .pink),
        AvatarPreset(id: "beer", name: "精釀暢飲", systemImage: "mug.fill", color: .orange),
        AvatarPreset(id: "moon", name: "夜貓跑者", systemImage: "moon.stars.fill", color: .purple),
        AvatarPreset(id: "fire", name: "派對熱情", systemImage: "flame.fill", color: .red)
    ]

    func redeemDrink() {
        guard passRedeemedDrinks < passTotalDrinks else { return }
        passRedeemedDrinks += 1
    }

    func selectPreset(_ preset: AvatarPreset) {
        selectedPresetId = preset.id
        // 以 SF Symbol 渲染為頭像圖片
        let image = Image(systemName: preset.systemImage)
        customAvatarImage = image
    }

    func resetDefaultAvatar() {
        selectedPresetId = nil
        customAvatarImage = nil
    }
}
