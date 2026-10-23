import Foundation

/// Each reader owns an index and at most three pages. JSON decoding runs on this actor, away from UI updates.
actor TranscriptPageSource {
    let file: URL
    let provider: ConversationProvider
    /// Picks the session out of a database that holds every session, as OpenCode's does.
    let sessionID: String?
    /// Reads a subagent's transcript; see `ClaudeTranscriptReader.includesSidechains`.
    let isSubagentTranscript: Bool
    let limits: TranscriptPageLimits
    /// See `TranscriptBuilder.decodesImages`.
    let decodesImages: Bool
    /// The index pages are read from; message search takes the byte offset of its final page from it.
    private(set) var fileIndex: TranscriptFileIndex?
    private var piRecordIndices: [Int]?

    init(
        file: URL,
        provider: ConversationProvider,
        sessionID: String? = nil,
        isSubagentTranscript: Bool = false,
        limits: TranscriptPageLimits = TranscriptPageLimits(),
        decodesImages: Bool = true
    ) {
        self.file = file
        self.provider = provider
        self.sessionID = sessionID
        self.isSubagentTranscript = isSubagentTranscript
        self.limits = limits
        self.decodesImages = decodesImages
    }

    /// `limits` overrides the source's page sizes for one call; the conversation map passes its own, keeping the reader's
    /// text and record cuts so entry IDs stay the reader's. Without `preparesMarkdown`, replies are not parsed (PERF-89).
    func read(
        _ request: TranscriptPageRequest, refreshIndex: Bool = false, limits pageLimits: TranscriptPageLimits? = nil,
        preparesMarkdown: Bool = true
    ) throws -> TranscriptPage {
        try Task.checkCancellation()
        let limits = pageLimits ?? self.limits
        let page = try readPage(request, refreshIndex: refreshIndex, limits: limits)
        return preparesMarkdown ? try page.preparingMarkdown() : page
    }

    private func readPage(_ request: TranscriptPageRequest, refreshIndex: Bool, limits: TranscriptPageLimits) throws -> TranscriptPage {
        if provider == .antigravity {
            return try AntigravityTranscriptPageSource.read(file, request: request, limits: limits)
        }
        if provider == .opencode {
            guard let sessionID else { throw OpenCodeDatabaseError.unreadable }
            return try OpenCodeTranscriptPageSource.read(file, sessionID: sessionID, request: request, limits: limits)
        }
        if fileIndex == nil || refreshIndex {
            let updatedIndex = try TranscriptFileIndex.read(file, updating: fileIndex)
            if updatedIndex.fingerprint != fileIndex?.fingerprint { piRecordIndices = nil }
            fileIndex = updatedIndex
        }
        let index = fileIndex!
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        if provider == .pi, piRecordIndices == nil {
            // The source's own limits, never a call's: the cached branch must not depend on who asked first.
            piRecordIndices = try TranscriptPiPageIndex.records(in: index, handle: handle, limits: self.limits)
        }
        let recordIndices = piRecordIndices
        let recordCount = recordIndices?.count ?? index.lineStarts.count
        let decoder = TranscriptRecordDecoder(
            provider: provider,
            maximumTextLength: limits.maximumTextLength,
            isSubagentTranscript: isSubagentTranscript,
            decodesImages: decodesImages
        )
        return try TranscriptPageReader.read(
            request, recordCount: recordCount, limits: limits,
            sourceID: { recordIndices?[$0] ?? $0 },
            decode: { position in
                let record = recordIndices?[position] ?? position
                return try autoreleasepool {
                    let data = try index.readRecord(at: record, from: handle, maximumByteCount: limits.maximumRecordByteCount)
                    return try decoder.pageEntries(from: data) { byteCount in
                        try handle.seek(toOffset: index.byteRange(at: record).lowerBound)
                        return try handle.read(upToCount: byteCount) ?? Data()
                    }
                }
            }
        )
    }
}
