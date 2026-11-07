import SwiftUI
import Observation
import UIKit

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
    var profileHandle: String = "@akai.afterdark"
    var profileBio: String = "用步行認識台中的夜晚。\n酒吧、街區，還有每一段剛剛好的路。"
    var profileLocation: String = "台中・西屯"
    var postCount: Int = 12
    var followingCount: Int = 268
    var followerCount: Int = 1_284
    var selectedPresetId: String? = nil
    var customAvatarData: Data?

    var customAvatarImage: Image? {
        if let customAvatarData, let image = UIImage(data: customAvatarData) {
            return Image(uiImage: image)
        }
        guard let selectedPresetId,
              let preset = Self.presets.first(where: { $0.id == selectedPresetId }) else { return nil }
        return Image(systemName: preset.systemImage)
    }

    private let avatarFileURL: URL

    init(avatarFileURL: URL? = nil) {
        self.avatarFileURL = avatarFileURL
            ?? URL.applicationSupportDirectory
                .appending(path: "BarHopping/Profile", directoryHint: .isDirectory)
                .appending(path: "avatar.jpg", directoryHint: .notDirectory)
        customAvatarData = try? Data(contentsOf: self.avatarFileURL)
        nickname = UserDefaults.standard.string(forKey: "profile.nickname") ?? "阿凱"
        profileBio = UserDefaults.standard.string(forKey: "profile.bio")
            ?? "用步行認識台中的夜晚。\n酒吧、街區，還有每一段剛剛好的路。"
    }

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
        customAvatarData = nil
        try? FileManager.default.removeItem(at: avatarFileURL)
    }

    func resetDefaultAvatar() {
        selectedPresetId = nil
        customAvatarData = nil
        try? FileManager.default.removeItem(at: avatarFileURL)
    }

    func setCustomAvatar(_ image: UIImage) throws {
        let maximumDimension: CGFloat = 1_024
        let originalSize = image.size
        let scale = min(1, maximumDimension / max(originalSize.width, originalSize.height))
        let targetSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let data = resizedImage.jpegData(compressionQuality: 0.86) else {
            throw AvatarStorageError.encodingFailed
        }

        try FileManager.default.createDirectory(
            at: avatarFileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: avatarFileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        customAvatarData = data
        selectedPresetId = nil
    }

    func updateProfile(nickname: String, bio: String) {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        self.nickname = trimmedNickname.isEmpty ? "BarHopping 旅人" : trimmedNickname
        profileBio = String(bio.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        UserDefaults.standard.set(self.nickname, forKey: "profile.nickname")
        UserDefaults.standard.set(profileBio, forKey: "profile.bio")
    }
}

private enum AvatarStorageError: Error {
    case encodingFailed
}
