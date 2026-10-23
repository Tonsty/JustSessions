import Foundation

/// A message bookmarked in a session's reader. Its `entryID` is the paged `TranscriptEntry.id` (`TranscriptPageIdentity`),
/// never an unpaged or export position.
struct MessageBookmark: Codable, Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case user, assistant

        /// Only your messages and the CLI's replies: a tool-call row's ID depends on where its page starts.
        init?(_ content: TranscriptEntry.Content) {
            switch content {
            case .userMessage: self = .user
            case .assistantMessage: self = .assistant
            default: return nil
            }
        }
    }

    /// "a" to "z", the lowest letter free in its session when it was added.
    let letter: String
    var entryID: Int
    let kind: Kind
    /// The head of the message's text on one line (`MessageBookmarkNavigation.snippet(of:)`), so the list reads without
    /// loading the message's page.
    var snippet: String

    /// For the reading toolbar's menu: at most 50 characters, with an ellipsis when cut.
    var menuSnippet: String { snippet.count > 50 ? String(snippet.prefix(49)) + "…" : snippet }
}

enum MessageBookmarkToggle: Equatable {
    case added(MessageBookmark), removed(MessageBookmark), allLettersInUse
}
