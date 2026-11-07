import Foundation

// MARK: - 讀取結果與錯誤

/// 某個草稿檔讀取失敗的原因。原檔保持不動，不刪除也不覆寫。
nonisolated struct DraftLoadFailure: Hashable, Sendable {
    enum Reason: Error, Hashable, Sendable {
        case unreadable(String)                 // 檔案讀不到
        case corrupted(String)                  // JSON 損壞或欄位不符
        case unsupportedSchemaVersion(Int?)     // schemaVersion != 1（nil 代表缺少此欄位）
    }

    var fileURL: URL
    var reason: Reason

    var fileName: String { fileURL.lastPathComponent }

    var message: String {
        switch reason {
        case .unreadable(let detail): "無法讀取草稿檔「\(fileName)」：\(detail)"
        case .corrupted(let detail): "草稿檔「\(fileName)」已損壞：\(detail)"
        case .unsupportedSchemaVersion(let v?): "草稿檔「\(fileName)」的版本 \(v) 不受支援"
        case .unsupportedSchemaVersion(nil): "草稿檔「\(fileName)」缺少版本資訊"
        }
    }
}

/// 一次讀取的完整結果：成功的草稿（依 savedAt 新到舊）與失敗清單。
nonisolated struct DraftLoadReport: Hashable, Sendable {
    var drafts: [SavedDraft]
    var failures: [DraftLoadFailure]
}

/// `loadAll()` 遇到任何失敗檔案時丟出；`report` 仍帶有可讀的草稿。
nonisolated struct DraftLoadError: LocalizedError, Hashable, Sendable {
    var report: DraftLoadReport

    var failures: [DraftLoadFailure] { report.failures }

    var errorDescription: String? {
        report.failures.map(\.message).joined(separator: "\n")
    }
}

// MARK: - FileDraftStore

/// 每份草稿一個 JSON 檔：Application Support/Drafts/<id>.json，日期為 ISO 8601。
/// actor 序列化所有讀寫；寫入使用 atomic write，不會留下寫一半的檔案。
actor FileDraftStore: DraftStoring {
    static let currentSchemaVersion = 1

    nonisolated let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL? = nil) {
        self.directory = directory
            ?? URL.applicationSupportDirectory.appending(path: "Drafts", directoryHint: .isDirectory)
    }

    /// 回傳成功的草稿與失敗清單；只有資料夾本身無法列出時才 throw。
    func loadAllReportingFailures() throws -> DraftLoadReport {
        guard fileManager.fileExists(atPath: directory.path(percentEncoded: false)) else {
            return DraftLoadReport(drafts: [], failures: [])
        }
        let files = try fileManager
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter { $0.pathExtension.lowercased() == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        let decoder = JSONCoding.makeDecoder()
        var drafts: [SavedDraft] = []
        var failures: [DraftLoadFailure] = []
        for file in files {
            switch Self.read(file, decoder: decoder) {
            case .success(let draft): drafts.append(draft)
            case .failure(let reason): failures.append(DraftLoadFailure(fileURL: file, reason: reason))
            }
        }
        drafts.sort { $0.savedAt > $1.savedAt }
        return DraftLoadReport(drafts: drafts, failures: failures)
    }

    /// 符合 `DraftStoring`：有任何失敗檔案時 throw `DraftLoadError`（其中仍帶成功的草稿）。
    func loadAll() throws -> [SavedDraft] {
        let report = try loadAllReportingFailures()
        guard report.failures.isEmpty else { throw DraftLoadError(report: report) }
        return report.drafts
    }

    func save(_ draft: SavedDraft) throws {
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONCoding.makeEncoder(pretty: true).encode(draft)
        try data.write(to: fileURL(for: draft.id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func delete(id: String) throws {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path(percentEncoded: false)) else { return }
        try fileManager.removeItem(at: url)
    }

    nonisolated func fileURL(for id: String) -> URL {
        directory.appending(path: Self.fileName(for: id), directoryHint: .notDirectory)
    }

    /// id 只保留安全字元，其餘以百分比編碼，避免路徑穿越。
    nonisolated static func fileName(for id: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-_")
        let safe = id.addingPercentEncoding(withAllowedCharacters: allowed) ?? UUID().uuidString
        return (safe.isEmpty ? "_" : safe) + ".json"
    }

    private struct VersionProbe: Decodable {
        struct Plan: Decodable { var schemaVersion: Int? }
        var plan: Plan
    }

    private static func read(_ file: URL, decoder: JSONDecoder) -> Result<SavedDraft, DraftLoadFailure.Reason> {
        let data: Data
        do { data = try Data(contentsOf: file) } catch { return .failure(.unreadable(error.localizedDescription)) }

        // 先確認版本，讓「版本不支援」與「檔案損壞」可以分開回報。
        let version: Int?
        do { version = try decoder.decode(VersionProbe.self, from: data).plan.schemaVersion }
        catch { return .failure(.corrupted(describe(error))) }
        guard version == currentSchemaVersion else { return .failure(.unsupportedSchemaVersion(version)) }

        do { return .success(try decoder.decode(SavedDraft.self, from: data)) }
        catch { return .failure(.corrupted(describe(error))) }
    }

    private static func describe(_ error: Error) -> String {
        switch error {
        case DecodingError.dataCorrupted(let c): c.debugDescription
        case DecodingError.keyNotFound(let key, _): "缺少欄位 \(key.stringValue)"
        case DecodingError.typeMismatch(_, let c), DecodingError.valueNotFound(_, let c):
            "欄位 \(c.codingPath.map(\.stringValue).joined(separator: ".")) 型別不符"
        default: error.localizedDescription
        }
    }
}

// MARK: - InMemoryDraftStore

/// 給 SwiftUI preview 與測試用，資料只存在記憶體。
actor InMemoryDraftStore: DraftStoring {
    private var drafts: [String: SavedDraft]

    init(drafts: [SavedDraft] = []) {
        self.drafts = Dictionary(drafts.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    func loadAll() -> [SavedDraft] { drafts.values.sorted { $0.savedAt > $1.savedAt } }
    func save(_ draft: SavedDraft) { drafts[draft.id] = draft }
    func delete(id: String) { drafts[id] = nil }
}
