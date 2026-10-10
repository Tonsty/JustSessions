import Foundation

/// Each session's text in a file of its own under Caches, so a search after a relaunch reads only the sessions that
/// changed. The cache is disposable: a file that can't be read, or was saved for another state of its session or by
/// another format, reads as missing.
struct SessionMessageTextCache: Sendable {
    /// Goes up when what is saved changes, such as which entries are kept, so text saved before is read again.
    static let formatVersion = 2
    /// How long the text of a session no longer listed is kept. A session can be missing from the list only for now,
    /// such as one on an SSH host not refreshed yet since launch, so its text is not deleted right away.
    static let unlistedRetention: TimeInterval = 30 * 24 * 60 * 60

    enum Lookup {
        case current(SessionMessageText)
        case reusable(SessionMessageText, SessionMessageTextReadState)
        case missing
    }

    let directory: URL

    static let standard = SessionMessageTextCache(
        directory: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppIdentity.currentBundleIdentifier)
            .appendingPathComponent("SessionMessages", isDirectory: true)
    )

    private struct Metadata: Codable, Equatable {
        let version: Int
        let conversationID: String
        let provider: ConversationProvider?
        let fingerprint: SessionMessageTextFingerprint
        let readState: SessionMessageTextReadState?
    }

    private static let magic = Data("JSMSTC2\n".utf8)

    func lookup(for conversation: Conversation, fingerprint: SessionMessageTextFingerprint) -> Lookup {
        guard let saved = saved(for: conversation.id),
              saved.version == Self.formatVersion,
              saved.conversationID == conversation.id else { return .missing }
        if saved.fingerprint == fingerprint {
            return (try? text(for: conversation.id, expecting: saved)).map(Lookup.current) ?? .missing
        }
        guard conversation.provider == .codex,
              saved.provider == .codex,
              saved.fingerprint.sourceFilePath == fingerprint.sourceFilePath,
              let state = saved.readState,
              let byteCount = fingerprint.byteCount,
              byteCount > state.byteCount,
              let text = try? text(for: conversation.id, expecting: saved) else { return .missing }
        return .reusable(text, state)
    }

    func text(for conversationID: String, fingerprint: SessionMessageTextFingerprint) -> SessionMessageText? {
        guard let saved = saved(for: conversationID),
              saved.version == Self.formatVersion,
              saved.conversationID == conversationID,
              saved.fingerprint == fingerprint else { return nil }
        return try? text(for: conversationID, expecting: saved)
    }

    @discardableResult
    func save(_ text: SessionMessageText, for conversationID: String, fingerprint: SessionMessageTextFingerprint) -> Int {
        saveEncoded(text, state: nil, provider: nil, for: conversationID, fingerprint: fingerprint)
    }

    @discardableResult
    func save(
        _ text: SessionMessageText,
        state: SessionMessageTextReadState?,
        provider: ConversationProvider,
        for conversationID: String,
        fingerprint: SessionMessageTextFingerprint
    ) -> Int {
        saveEncoded(text, state: state, provider: provider, for: conversationID, fingerprint: fingerprint)
    }

    /// Deletes the saved text of sessions other than `listedConversationIDs` once it has gone unsaved for
    /// `unlistedRetention`, such as that of deleted sessions or of a removed SSH host's.
    func removeText(ofSessionsOtherThan listedConversationIDs: Set<String>, now: Date = .now) {
        let listedFileNames = Set(listedConversationIDs.map(Self.fileName(for:)))
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        for file in files where !listedFileNames.contains(file.lastPathComponent) {
            let savedAt = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if now.timeIntervalSince(savedAt) > Self.unlistedRetention { try? FileManager.default.removeItem(at: file) }
        }
    }

    private func saveEncoded(
        _ text: SessionMessageText,
        state: SessionMessageTextReadState?,
        provider: ConversationProvider?,
        for conversationID: String,
        fingerprint: SessionMessageTextFingerprint
    ) -> Int {
        let metadata = Metadata(
            version: Self.formatVersion,
            conversationID: conversationID,
            provider: provider,
            fingerprint: fingerprint,
            readState: state
        )
        guard let metadataData = try? JSONEncoder().encode(metadata),
              metadataData.count <= Int(UInt32.max),
              let textData = try? JSONEncoder().encode(text) else { return 0 }
        var data = Self.magic
        var metadataLength = UInt32(metadataData.count).bigEndian
        withUnsafeBytes(of: &metadataLength) { data.append(contentsOf: $0) }
        data.append(metadataData)
        data.append(textData)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: file(for: conversationID), options: .atomic)
            return data.count
        } catch {
            return 0
        }
    }

    private func saved(for conversationID: String) -> Metadata? {
        guard let handle = try? FileHandle(forReadingFrom: file(for: conversationID)) else { return nil }
        defer { try? handle.close() }
        return try? header(from: handle).metadata
    }

    /// Rechecks the small header and reads its payload from the same descriptor, so an atomic save by another
    /// consumer can yield either complete generation but never one generation's metadata with another's text.
    private func text(for conversationID: String, expecting expected: Metadata) throws -> SessionMessageText {
        let handle = try FileHandle(forReadingFrom: file(for: conversationID))
        defer { try? handle.close() }
        let saved = try header(from: handle)
        guard saved.metadata == expected else { throw CocoaError(.fileReadCorruptFile) }
        try handle.seek(toOffset: saved.payloadOffset)
        return try JSONDecoder().decode(SessionMessageText.self, from: handle.readToEnd() ?? Data())
    }

    private func header(from handle: FileHandle) throws -> (metadata: Metadata, payloadOffset: UInt64) {
        guard let prefix = try handle.read(upToCount: Self.magic.count + MemoryLayout<UInt32>.size),
              prefix.count == Self.magic.count + MemoryLayout<UInt32>.size,
              prefix.prefix(Self.magic.count) == Self.magic else { throw CocoaError(.fileReadCorruptFile) }
        let lengthBytes = prefix.suffix(MemoryLayout<UInt32>.size)
        let metadataLength = lengthBytes.reduce(UInt32(0)) { ($0 << 8) | UInt32($1) }
        guard metadataLength <= 1 << 20,
              let metadataData = try handle.read(upToCount: Int(metadataLength)),
              metadataData.count == Int(metadataLength) else { throw CocoaError(.fileReadCorruptFile) }
        return (
            try JSONDecoder().decode(Metadata.self, from: metadataData),
            UInt64(prefix.count) + UInt64(metadataLength)
        )
    }

    private func file(for conversationID: String) -> URL {
        directory.appendingPathComponent(Self.fileName(for: conversationID))
    }

    /// The session's ID with every character but ASCII letters, digits, `-`, `_`, and `.` percent-encoded, so the `:`,
    /// `@`, and spaces in IDs never reach a file name.
    private static func fileName(for conversationID: String) -> String {
        (conversationID.addingPercentEncoding(withAllowedCharacters: fileNameCharacters) ?? conversationID) + ".json"
    }

    private static let fileNameCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_."
    )
}
