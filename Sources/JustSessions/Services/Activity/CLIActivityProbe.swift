import Foundation

/// A running CLI, and what it takes to ask it what it is doing.
struct CLIActivityProbe: Sendable {
    let provider: ConversationProvider
    /// The CLI's process, or 0 while it is unknown, such as just after a tab's tmux session started.
    let processID: Int32
    /// The session's file, where Codex records its turns; nil before a new session's file is known.
    let sessionFile: URL?
    /// The session's id, which names a Codex thread on Codex's background server; nil while it is unknown.
    var sessionID: String? = nil
    /// The title the CLI last gave its tab's terminal, where Codex says what it is doing; see `CodexTitleActivity`. On
    /// an SSH host, the tab's tmux session puts what Claude Code, Pi, or OpenCode does in it; see
    /// `RemoteCLIActivityTitle`.
    var terminalTitle: String? = nil
}

extension TerminalSession {
    /// Nil for a plain terminal, which runs no CLI. A CLI on an SSH host tells only through the title, which tmux on the
    /// host passes to the tab; its process is out of reach, and the copy of a session file on this Mac is only as new
    /// as the host's last refresh.
    var cliActivityProbe: CLIActivityProbe? {
        guard let provider else { return nil }
        guard host == .thisMac else {
            guard provider == .codex || RemoteCLIActivityTitle.providers.contains(provider) else { return nil }
            return CLIActivityProbe(provider: provider, processID: 0, sessionFile: nil, terminalTitle: terminalTitle)
        }
        return CLIActivityProbe(
            provider: provider,
            processID: cliProcessID,
            sessionFile: conversation?.sourceFile,
            sessionID: conversation?.sessionID,
            terminalTitle: terminalTitle
        )
    }
}
