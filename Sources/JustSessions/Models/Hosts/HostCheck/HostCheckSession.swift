import Foundation

/// The tab a check from an ended tab is about, so the check also looks at its folder on the host and, for a session's
/// tab, at its CLI.
struct HostCheckSession: Equatable, Sendable {
    /// Nil for a plain terminal.
    let provider: ConversationProvider?
    let projectPath: String
}
