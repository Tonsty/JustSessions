import Foundation

/// What a search finds bookmarks by: `#tag` finds bookmarks with a tag that starts with `tag`; other text finds bookmarks
/// whose label or a tag contains it, or, where asked, the head of the message. Case and accents are ignored. The sidebar
/// leaves the message out, since its message search already finds that text (SBF-05); All Bookmarks keeps it (RDR-52).
struct MessageBookmarkQuery: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case tagPrefix(String)
        case text(String)
    }

    let kind: Kind

    /// Nil for text with nothing to search for, such as spaces or a lone `#`.
    init?(_ typed: String) {
        let trimmed = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            let tag = MessageBookmarkDetails.searchKey(String(trimmed.drop { $0 == "#" }))
            guard !tag.isEmpty else { return nil }
            kind = .tagPrefix(tag)
        } else {
            guard !trimmed.isEmpty else { return nil }
            kind = .text(MessageBookmarkDetails.searchKey(trimmed))
        }
    }

    func matches(_ bookmark: MessageBookmark, includingSnippet: Bool) -> Bool {
        switch kind {
        case .tagPrefix(let prefix):
            return bookmark.tags.contains { MessageBookmarkDetails.searchKey($0).hasPrefix(prefix) }
        case .text(let text):
            return bookmark.label.map { MessageBookmarkDetails.searchKey($0).contains(text) } == true
                || bookmark.tags.contains { MessageBookmarkDetails.searchKey($0).contains(text) }
                || (includingSnippet && MessageBookmarkDetails.searchKey(bookmark.snippet).contains(text))
        }
    }

    /// For All Bookmarks: also its session's title, so a session's name finds all its bookmarks.
    func matches(sessionTitle: String) -> Bool {
        guard case .text(let text) = kind else { return false }
        return MessageBookmarkDetails.searchKey(sessionTitle).contains(text)
    }
}
