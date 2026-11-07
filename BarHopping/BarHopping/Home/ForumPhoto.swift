import Foundation

/// 隨 App 打包的論壇情境照，不需要網路即可顯示。
struct ForumPhoto: Identifiable, Hashable, Sendable {
    let imageName: String
    let description: String
    let author: String
    let sourceURL: URL

    var id: String { imageName }
    var credit: String { "照片：\(author) / Pexels / Pexels License" }
}
