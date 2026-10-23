import Foundation

/// The session a Claude Code tab's CLI moved to, with `/clear`, `/resume`, or `/branch`, while no refresh of the tab's
/// host has listed it. The tab stays linked to the session it was in, keeps asking for refreshes until one lists the
/// new one (LIV-07), and meanwhile shows, and renames, the new one (LIV-01, LIV-08); see `followClaudeSessionSwitch`.
struct UnlistedClaudeSession: Equatable {
    let sessionID: String
    /// When the tab first saw its CLI in it: a refresh that started before may have read the host before the move.
    let movedAt: Date
    /// When the tab last asked for a refresh to list it; nil until it has.
    var refreshRequestedAt: Date?
    /// On an SSH host, the relay's title when the tab last asked; see `askToList`.
    var terminalTitleAtRequest: String?
    /// The name the CLI chose for it, which the tab shows, and never the row of the session it is still linked to.
    var chosenName: String?
}
