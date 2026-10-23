import Foundation

/// Each session's bookmarks, keyed by `Conversation.id`, each list in conversation order with one bookmark per letter
/// and per message.
struct MessageBookmarks: Equatable {
    static let userDefaultsKey = "messageBookmarks"
    static let letters = "abcdefghijklmnopqrstuvwxyz".map(String.init)

    private(set) var bookmarksByConversationID: [String: [MessageBookmark]]

    init(bookmarksByConversationID: [String: [MessageBookmark]] = [:]) {
        self.bookmarksByConversationID = bookmarksByConversationID.compactMapValues(Self.normalized)
    }

    static func load(from userDefaults: UserDefaults) -> MessageBookmarks {
        guard let data = userDefaults.data(forKey: userDefaultsKey),
              let saved = try? JSONDecoder().decode([String: [MessageBookmark]].self, from: data) else { return MessageBookmarks() }
        return MessageBookmarks(bookmarksByConversationID: saved)
    }

    func save(to userDefaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(bookmarksByConversationID) else { return }
        userDefaults.set(data, forKey: Self.userDefaultsKey)
    }

    func bookmarks(forConversationID conversationID: String) -> [MessageBookmark] {
        bookmarksByConversationID[conversationID] ?? []
    }

    /// Removes the message's bookmark, or adds one with the lowest free letter.
    mutating func toggle(entryID: Int, kind: MessageBookmark.Kind, snippet: String, conversationID: String) -> MessageBookmarkToggle {
        var bookmarks = bookmarks(forConversationID: conversationID)
        if let index = bookmarks.firstIndex(where: { $0.entryID == entryID }) {
            let removed = bookmarks.remove(at: index)
            set(bookmarks, forConversationID: conversationID)
            return .removed(removed)
        }
        guard let letter = Self.letters.first(where: { letter in !bookmarks.contains { $0.letter == letter } }) else {
            return .allLettersInUse
        }
        let added = MessageBookmark(letter: letter, entryID: entryID, kind: kind, snippet: snippet)
        set(bookmarks + [added], forConversationID: conversationID)
        return .added(added)
    }

    /// Only the bookmark with this letter on this message, never one that took the letter since.
    mutating func remove(_ bookmark: MessageBookmark, conversationID: String) {
        set(bookmarks(forConversationID: conversationID).filter { $0.letter != bookmark.letter || $0.entryID != bookmark.entryID },
            forConversationID: conversationID)
    }

    mutating func removeAll(forConversationIDs conversationIDs: some Sequence<String>) {
        for conversationID in conversationIDs { bookmarksByConversationID[conversationID] = nil }
    }

    /// After a jump found the message at another part of its record, or with more of its text. If another bookmark
    /// already marks that message, the moved one goes.
    mutating func update(_ bookmark: MessageBookmark, entryID: Int, snippet: String, conversationID: String) {
        var bookmarks = bookmarks(forConversationID: conversationID)
        guard let index = bookmarks.firstIndex(where: { $0.letter == bookmark.letter && $0.entryID == bookmark.entryID }) else { return }
        if entryID != bookmark.entryID, bookmarks.contains(where: { $0.entryID == entryID }) {
            bookmarks.remove(at: index)
        } else {
            bookmarks[index].entryID = entryID
            bookmarks[index].snippet = snippet
        }
        set(bookmarks, forConversationID: conversationID)
    }

    private mutating func set(_ bookmarks: [MessageBookmark], forConversationID conversationID: String) {
        bookmarksByConversationID[conversationID] = Self.normalized(bookmarks)
    }

    /// Sorted by entry ID; only letters a–z; one bookmark per letter and per message; nil, dropping the key, when empty.
    private static func normalized(_ bookmarks: [MessageBookmark]) -> [MessageBookmark]? {
        var usedLetters = Set<String>(), markedEntryIDs = Set<Int>(), kept: [MessageBookmark] = []
        for bookmark in bookmarks.sorted(by: { ($0.entryID, $0.letter) < ($1.entryID, $1.letter) })
        where letters.contains(bookmark.letter) && !usedLetters.contains(bookmark.letter) && !markedEntryIDs.contains(bookmark.entryID) {
            usedLetters.insert(bookmark.letter); markedEntryIDs.insert(bookmark.entryID); kept.append(bookmark)
        }
        return kept.isEmpty ? nil : kept
    }
}
