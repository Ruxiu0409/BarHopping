import Foundation

/// API 與本機草稿共用的 JSON 設定。日期一律為含 UTC 時區的 ISO 8601 字串。
/// 解碼時接受有或沒有小數秒，以及任何時區位移；編碼時輸出 UTC 並帶毫秒。
nonisolated enum JSONCoding {
    static func parseISO8601(_ string: String) -> Date? {
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string) { return date }
        return try? Date.ISO8601FormatStyle().parse(string)
    }

    static func formatISO8601(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(includingFractionalSeconds: true))
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = parseISO8601(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "無法解析 ISO 8601 日期：\(raw)")
            }
            return date
        }
        return decoder
    }

    static func makeEncoder(pretty: Bool = false) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatISO8601(date))
        }
        encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes] : [.withoutEscapingSlashes]
        return encoder
    }
}
