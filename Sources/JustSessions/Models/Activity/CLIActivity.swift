import Foundation

/// What a running CLI is doing, as far as it tells: Claude Code in its live process registry, Codex in its terminal
/// title, or in its session file and through its background server, Antigravity in its conversation database, Pi and
/// OpenCode through the app's extension, and Kiro CLI in its turn markers. A CLI that tells nothing, such as a Kiro
/// CLI too old to mark its turns, or Antigravity on an SSH host without `python3`, has no activity; it only runs.
enum CLIActivity: Equatable, Sendable {
    /// Working on a turn.
    case working
    /// Stopped in the middle of a turn until you answer, such as a permission prompt. `reason` is the CLI's own
    /// words for it, such as "input needed".
    case needsInput(reason: String?)
    /// Done with its turn, waiting for your next prompt.
    case idle

    static let maximumWaitReasonLength = 60

    /// Waiting on you for what the CLI says, on one line and shortened; no reason when it says nothing. A Pi
    /// extension's prompt title can span lines.
    static func needsInput(reportedReason: String?) -> CLIActivity {
        let reason = (reportedReason ?? "").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        return .needsInput(reason: reason.isEmpty ? nil : String(reason.prefix(maximumWaitReasonLength)))
    }
}
