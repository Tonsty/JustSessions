import CryptoKit
import Darwin
import Foundation

struct SessionMessageTextReadState: Sendable, Codable, Equatable {
    let device: Int32
    let inode: UInt64
    let byteCount: UInt64
    let modifiedSeconds: Int
    let modifiedNanoseconds: Int
    let digest: Data
    /// The start of the last page, which must be reparsed because an append can change its tool-call merging and end.
    let resumeByteOffset: UInt64
    let resumeRecord: Int
    let committedEntryCount: Int

    func identifiesSameFile(as fingerprint: TranscriptFileFingerprint) -> Bool {
        device == fingerprint.device && inode == fingerprint.inode
    }
}

struct SessionMessageTextReadResult: Sendable {
    let text: SessionMessageText
    let state: SessionMessageTextReadState?
    let sourceByteCountRead: UInt64
    let decodedRecordCount: Int
}

/// Reads a whole session the way its reader pages through it, keeping the text of what you wrote, the CLI's replies,
/// and its tool calls. Notes, such as one for a record too large to show, and images are left out. Images are not even
/// decoded: their entries only hold their place, so every other entry keeps the ID the reader gives it.
enum SessionMessageTextReader {
    /// The reader's own cuts of long messages and large records, so a search never finds text the reader leaves out,
    /// in pages far larger than the reader's, as a session is read from start to end in one go.
    static let wholeSessionLimits = TranscriptPageLimits(
        targetEntryCount: 5_000, maximumRecordCount: 50_000, targetByteCount: 64 << 20
    )

    static func read(_ conversation: Conversation, limits: TranscriptPageLimits = wholeSessionLimits) async throws -> SessionMessageText {
        try await readResult(conversation, limits: limits).text
    }

    static func readResult(
        _ conversation: Conversation,
        resuming previous: (text: SessionMessageText, state: SessionMessageTextReadState)? = nil,
        limits: TranscriptPageLimits = wholeSessionLimits
    ) async throws -> SessionMessageTextReadResult {
        guard conversation.provider == .codex else {
            let text = try await readWithPageSource(conversation, limits: limits)
            return SessionMessageTextReadResult(text: text, state: nil, sourceByteCountRead: 0, decodedRecordCount: 0)
        }
        return try readCodex(conversation, resuming: previous, limits: limits)
    }

    private static func readWithPageSource(_ conversation: Conversation, limits: TranscriptPageLimits) async throws -> SessionMessageText {
        let source = TranscriptPageSource(
            file: conversation.sourceFile, provider: conversation.provider, sessionID: conversation.sessionID, limits: limits,
            decodesImages: false
        )
        var entries: [SessionMessageText.Entry] = []
        var request = TranscriptPageRequest.first
        while true {
            let page = try await source.read(request)
            entries += page.entries.compactMap(searchedEntry)
            guard page.hasLater else { return SessionMessageText(entries: entries) }
            request = .after(page.records.upperBound)
        }
    }

    private static func readCodex(
        _ conversation: Conversation,
        resuming previous: (text: SessionMessageText, state: SessionMessageTextReadState)?,
        limits: TranscriptPageLimits
    ) throws -> SessionMessageTextReadResult {
        let handle = try FileHandle(forReadingFrom: conversation.sourceFile)
        defer { try? handle.close() }
        let fingerprint = try TranscriptFileFingerprint(handle: handle)
        let canResume = previous.map {
            $0.state.identifiesSameFile(as: fingerprint)
                && fingerprint.byteCount > $0.state.byteCount
                && $0.state.resumeByteOffset <= $0.state.byteCount
                && $0.state.committedEntryCount <= $0.text.entries.count
        } ?? false
        let resumed = canResume ? previous : nil
        var collector = CodexTextCollector(
            limits: limits,
            entries: resumed.map { Array($0.text.entries.prefix($0.state.committedEntryCount)) } ?? [],
            record: resumed?.state.resumeRecord ?? 0,
            pageStartOffset: resumed?.state.resumeByteOffset ?? 0
        )
        let resumeOffset = resumed?.state.resumeByteOffset ?? 0
        let previousByteCount = resumed?.state.byteCount ?? 0
        var previousHasher = SHA256()
        var wholeHasher = SHA256()
        var offset: UInt64 = 0
        var sourceByteCountRead: UInt64 = 0
        try handle.seek(toOffset: 0)
        while offset < fingerprint.byteCount {
            try Task.checkCancellation()
            let count = Int(min(UInt64(1 << 20), fingerprint.byteCount - offset))
            guard let chunk = try autoreleasepool(invoking: { try handle.read(upToCount: count) }),
                  !chunk.isEmpty else { throw TranscriptPagingError.sourceChanged }
            sourceByteCountRead += UInt64(chunk.count)
            wholeHasher.update(data: chunk)
            if offset < previousByteCount {
                let oldCount = Int(min(UInt64(chunk.count), previousByteCount - offset))
                previousHasher.update(data: chunk.prefix(oldCount))
            }
            let chunkEnd = offset + UInt64(chunk.count)
            if chunkEnd > resumeOffset {
                let start = Int(max(offset, resumeOffset) - offset)
                try autoreleasepool { try collector.consume(chunk.dropFirst(start), endingAt: chunkEnd) }
            }
            offset = chunkEnd
        }
        try collector.finish(at: fingerprint.byteCount)
        let after = try TranscriptFileFingerprint(handle: handle)
        guard after == fingerprint else { throw TranscriptPagingError.sourceChanged }
        if let resumed, Data(previousHasher.finalize()) != resumed.state.digest {
            return try readCodex(conversation, resuming: nil, limits: limits)
        }
        let text = SessionMessageText(entries: collector.entries)
        let state = SessionMessageTextReadState(
            device: fingerprint.device,
            inode: fingerprint.inode,
            byteCount: fingerprint.byteCount,
            modifiedSeconds: fingerprint.modifiedSeconds,
            modifiedNanoseconds: fingerprint.modifiedNanoseconds,
            digest: Data(wholeHasher.finalize()),
            resumeByteOffset: collector.pageStartOffset,
            resumeRecord: collector.pageStartRecord,
            committedEntryCount: collector.committedEntryCount
        )
        return SessionMessageTextReadResult(
            text: text,
            state: state,
            sourceByteCountRead: sourceByteCountRead,
            decodedRecordCount: collector.decodedRecordCount
        )
    }

    fileprivate static func searchedEntry(_ entry: TranscriptEntry) -> SessionMessageText.Entry? {
        switch entry.content {
        case .userMessage, .assistantMessage, .toolCalls:
            let segments = TranscriptSearchSegments.texts(in: entry)
            return segments.isEmpty ? nil : SessionMessageText.Entry(id: entry.id, segments: segments)
        case .note, .userImage, .toolResultImage:
            return nil
        }
    }
}

private struct CodexTextCollector {
    let limits: TranscriptPageLimits
    var entries: [SessionMessageText.Entry]
    var record: Int
    var pageStartOffset: UInt64
    var pageStartRecord: Int
    var committedEntryCount: Int
    var decodedRecordCount = 0

    private var pending = Data()
    private var pendingHead = Data()
    private var pendingByteCount = 0
    private var pageRecords: [(Int, [TranscriptEntry])] = []
    private var pageEntryCount = 0
    private var pageByteCount = 0
    private var pageRecordCount = 0

    init(limits: TranscriptPageLimits, entries: [SessionMessageText.Entry], record: Int, pageStartOffset: UInt64) {
        self.limits = limits
        self.entries = entries
        self.record = record
        self.pageStartOffset = pageStartOffset
        pageStartRecord = record
        committedEntryCount = entries.count
    }

    mutating func consume(_ bytes: Data.SubSequence, endingAt absoluteEnd: UInt64) throws {
        var start = bytes.startIndex
        while let newline = bytes[start...].firstIndex(of: UInt8(ascii: "\n")) {
            let end = bytes.index(after: newline)
            append(bytes[start..<end])
            let bytesAfterRecord = bytes.distance(from: end, to: bytes.endIndex)
            try processRecord(endingAt: absoluteEnd - UInt64(bytesAfterRecord))
            start = end
        }
        if start < bytes.endIndex { append(bytes[start...]) }
    }

    mutating func finish(at byteCount: UInt64) throws {
        if pendingByteCount > 0 { try processRecord(endingAt: byteCount) }
        flushPage(committing: false, nextOffset: byteCount)
    }

    private mutating func append(_ bytes: Data.SubSequence) {
        pendingByteCount += bytes.count
        if pendingHead.count < 512 { pendingHead.append(contentsOf: bytes.prefix(512 - pendingHead.count)) }
        if pending.count <= limits.maximumRecordByteCount,
           pending.count + bytes.count <= limits.maximumRecordByteCount {
            pending.append(contentsOf: bytes)
        } else {
            pending.removeAll(keepingCapacity: true)
        }
    }

    private mutating func processRecord(endingAt endOffset: UInt64) throws {
        try Task.checkCancellation()
        let data: Data? = pendingByteCount <= limits.maximumRecordByteCount ? pending : nil
        let rawEntries: [TranscriptEntry] = autoreleasepool {
            if data == nil, !CodexTranscriptReader.mightContainTranscriptItem(pendingHead) { return [] }
            if data != nil, CodexTranscriptReader.mightContainTranscriptItem(pendingHead) { decodedRecordCount += 1 }
            return TranscriptRecordDecoder(
                provider: .codex, maximumTextLength: limits.maximumTextLength, decodesImages: false
            ).entries(from: data)
        }
        pageRecords.append((record, rawEntries))
        pageEntryCount += rawEntries.count
        pageByteCount += data?.count ?? 0
        pageRecordCount += 1
        record += 1
        pending.removeAll(keepingCapacity: true)
        pendingHead.removeAll(keepingCapacity: true)
        pendingByteCount = 0
        if pageEntryCount > 0 && (pageEntryCount >= limits.targetEntryCount
            || pageRecordCount >= limits.maximumRecordCount || pageByteCount >= limits.targetByteCount) {
            flushPage(committing: true, nextOffset: endOffset)
        }
    }

    private mutating func flushPage(committing: Bool, nextOffset: UInt64) {
        guard !pageRecords.isEmpty else { return }
        entries += TranscriptPageAssembler.entries(in: pageRecords).compactMap(SessionMessageTextReader.searchedEntry)
        pageRecords.removeAll(keepingCapacity: true)
        pageEntryCount = 0
        pageByteCount = 0
        pageRecordCount = 0
        if committing {
            pageStartOffset = nextOffset
            pageStartRecord = record
            committedEntryCount = entries.count
        }
    }
}
