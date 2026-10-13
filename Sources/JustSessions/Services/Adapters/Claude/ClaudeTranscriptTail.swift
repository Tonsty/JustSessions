import Foundation

/// What the last lines of a Claude Code transcript say about its session, found without reading the whole file.
struct ClaudeTranscriptTail: Sendable, Codable {
    static let maximumByteCount = 262_144
    /// Bytes every `relocated` line holds. Once the timestamp and title are known, only lines holding them are parsed.
    private static let relocatedWorkingDirectoryKey = Data(#""relocatedCwd""#.utf8)

    /// The `timestamp` of the last line that has one.
    private(set) var latestTimestamp: Date?
    /// The title from the last `custom-title` line that has one.
    private(set) var latestCustomTitle: String?
    /// The `relocatedCwd` of the last `relocated` line: the folder `/cd` moved the session to. Claude Code moves the
    /// transcript into that folder's project directory and reads the session's folder from here, ahead of any `cwd`,
    /// which also changes whenever its shell changes directory.
    private(set) var relocatedWorkingDirectory: String?

    init(file: URL) {
        self.init(lines: JSONLinesReader.trailingLines(in: file, maximumByteCount: Self.maximumByteCount))
    }

    /// `lines` are oldest first, as they are in the file.
    init(lines: [Data]) {
        for line in lines.reversed() {
            if latestTimestamp != nil, latestCustomTitle != nil,
               line.range(of: Self.relocatedWorkingDirectoryKey) == nil { continue }
            guard let record = ConversationMetadata.object(from: line) else { continue }
            if latestTimestamp == nil {
                latestTimestamp = ConversationMetadata.date(record["timestamp"])
            }
            if latestCustomTitle == nil, record["type"] as? String == "custom-title" {
                latestCustomTitle = record["customTitle"] as? String
            }
            if relocatedWorkingDirectory == nil, record["type"] as? String == "relocated" {
                relocatedWorkingDirectory = record["relocatedCwd"] as? String
            }
            if latestTimestamp != nil, latestCustomTitle != nil, relocatedWorkingDirectory != nil { break }
        }
    }
}
