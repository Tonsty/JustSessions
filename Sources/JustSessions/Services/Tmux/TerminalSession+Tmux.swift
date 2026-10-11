import Foundation

extension TerminalSession {
    /// Whether closing the tab can leave its CLI running in tmux. On this Mac the tab's tmux client ends when its
    /// session does; over SSH it also ends when the connection drops, with the CLI still running on the host. A tab
    /// still waiting to be shown has started nothing.
    var canKeepCLIRunningAfterClose: Bool {
        tmuxSessionName != nil && !isWaitingToBeShown && (host != .thisMac || !hasExited)
    }

    /// Whether closing the tab stops nothing, so it closes without asking: its CLI or shell already ended, and no tmux
    /// on an SSH host may still run it.
    var closingStopsNothing: Bool {
        hasExited && !canKeepCLIRunningAfterClose
    }
}
