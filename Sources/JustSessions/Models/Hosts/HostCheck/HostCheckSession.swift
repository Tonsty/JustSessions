import Foundation

/// The tab a check from an ended tab is about, so the check also looks at its folder on the host and, for a session's
/// tab, at its CLI, and its report keeps what the tab showed.
struct HostCheckSession: Equatable, Sendable {
    /// Nil for a plain terminal.
    let provider: ConversationProvider?
    let projectPath: String
    /// The tab's last lines; see `TerminalSession.shownTextForHostCheck`.
    var endedTabScreen: String? = nil
}
