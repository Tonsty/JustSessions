import Foundation

/// The title a Claude Code tab's tmux session on an SSH host gives the tab: what the CLI's record in the host's live
/// registry says, after `titlePrefix`, as `RemoteClaudeActivityRelay` keeps it in `optionName`. Until the relay first
/// sets it, as before Claude Code writes its record, the title is the CLI's own, except that tmux 2.6 shows the prefix
/// alone. The app shows neither; it only reads what the CLI does from it.
enum RemoteClaudeActivityTitle {
    /// A window option of the tab's tmux session, holding `<status>:<waitingFor>` from the record.
    static let optionName = "@justsessions-claude-activity"
    static let titlePrefix = "justsessions-claude-activity:"
    /// The session's `set-titles-string`.
    static let titleFormat = "#{?\(optionName),\(titlePrefix)#{\(optionName)},#T}"

    /// Nil for any other title, and for a status this app does not know, as `ClaudeLiveSessionRecord` reads it.
    static func activity(inTerminalTitle title: String) -> CLIActivity? {
        guard title.hasPrefix(titlePrefix) else { return nil }
        let record = title.dropFirst(titlePrefix.count)
        let status = record.prefix { $0 != ":" }
        let waitingFor = record.dropFirst(status.count).dropFirst()
        return ClaudeLiveSessionRecord.activity(
            status: String(status),
            waitingFor: waitingFor.isEmpty ? nil : String(waitingFor)
        )
    }
}
