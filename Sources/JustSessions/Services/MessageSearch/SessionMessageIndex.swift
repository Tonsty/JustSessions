import Foundation

/// Every listed session's searchable text, in memory while a window searches them. A session's text is read once
/// and saved in `cache`, then read again only after the session changes.
actor SessionMessageIndex {
    private struct IndexedSession {
        let fingerprint: SessionMessageTextFingerprint
        let text: SearchableSessionText
    }

    nonisolated let cache: SessionMessageTextCache
    private var sessions: [String: IndexedSession] = [:]

    init(cache: SessionMessageTextCache = .standard) {
        self.cache = cache
    }

    /// Of `conversations`, in their order, those whose text in memory is missing or older than the session, each with
    /// the session's current fingerprint. Sessions no longer listed leave memory.
    func sessionsToRead(among conversations: [Conversation]) -> [(Conversation, SessionMessageTextFingerprint)] {
        let listedIDs = Set(conversations.map(\.id))
        sessions = sessions.filter { listedIDs.contains($0.key) }
        return conversations.compactMap { conversation in
            let fingerprint = SessionMessageTextFingerprint(conversation)
            return sessions[conversation.id]?.fingerprint == fingerprint ? nil : (conversation, fingerprint)
        }
    }

    func add(_ text: SearchableSessionText, fingerprint: SessionMessageTextFingerprint, for conversationID: String) {
        sessions[conversationID] = IndexedSession(fingerprint: fingerprint, text: text)
    }

    /// Each session with `query`, and its first match. Stops when the calling task is cancelled.
    func matches(for query: SessionMessageQuery) throws -> [String: SessionMessageMatch] {
        var matches: [String: SessionMessageMatch] = [:]
        for (conversationID, session) in sessions {
            try Task.checkCancellation()
            if let match = session.text.firstMatch(of: query) { matches[conversationID] = match }
        }
        return matches
    }

    /// Frees the memory once no window searches; the cache keeps the text for the next search.
    func removeAll() {
        sessions = [:]
    }

    func removeSavedText(ofSessionsOtherThan listedConversationIDs: Set<String>) {
        cache.removeText(ofSessionsOtherThan: listedConversationIDs)
    }

    /// The session's text from the cache, or else read from the session and saved. Codex append-only logs resume at
    /// the last uncommitted page after their saved prefix is validated. Nil when the session can't be read, or the
    /// read is cancelled; a later update tries again.
    nonisolated static func searchableText(
        of conversation: Conversation, fingerprint: SessionMessageTextFingerprint, cache: SessionMessageTextCache
    ) async -> SearchableSessionText? {
        let previous: (text: SessionMessageText, state: SessionMessageTextReadState)?
        switch cache.lookup(for: conversation, fingerprint: fingerprint) {
        case .current(let text):
            return SearchableSessionText(text)
        case .reusable(let text, let state):
            previous = (text, state)
        case .missing:
            previous = nil
        }
        guard let result = try? await SessionMessageTextReader.readResult(conversation, resuming: previous),
              !Task.isCancelled else { return nil }
        cache.save(
            result.text, state: result.state, provider: conversation.provider,
            for: conversation.id, fingerprint: fingerprint
        )
        return SearchableSessionText(result.text)
    }
}
