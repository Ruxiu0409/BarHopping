import SwiftUI
import UIKit

/// 使用者預設大頭貼（Assets 的 `UserAvatar`）。
enum UserAvatarIcon {
    static let assetName = "UserAvatar"

    /// Tab bar 用的小圓形圖示。Tab bar 會把圖片當成單色樣板並用原始尺寸顯示，
    /// 所以先裁成指定大小的圓形，並設為 alwaysOriginal 保留照片顏色。
    static func tabImage(diameter: CGFloat = 28) -> UIImage {
        guard let source = UIImage(named: assetName) else { return UIImage() }
        let size = CGSize(width: diameter, height: diameter)
        let rendered = UIGraphicsImageRenderer(size: size).image { _ in
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).addClip()
            source.draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.withRenderingMode(.alwaysOriginal)
    }
}
