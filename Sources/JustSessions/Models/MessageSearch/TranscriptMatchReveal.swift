import Foundation

/// Opens a session's reader at a match that a search through every session's messages found, with Find showing the
/// searched text there. Each click on a session row makes a new one, so clicking the row again shows the match again.
struct TranscriptMatchReveal: Equatable {
    let id = UUID()
    let conversationID: String
    /// The reader's ID for the entry with the match.
    let entryID: Int
    /// Empty for a bookmark the sidebar found by its label or tag (SBF-05): the reader shows its message without Find.
    let query: String
}
