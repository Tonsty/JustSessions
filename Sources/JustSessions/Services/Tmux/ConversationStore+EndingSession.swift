import Foundation

/// End session, from a session's row: stops its CLI wherever it runs, in a tab of any window or in tmux without one.
/// Closing a tab is what keeps the CLI running; ending the session closes its tabs too.
extension ConversationStore {
    /// Whether the session's CLI runs, or starts once its tab shows, in a tab of any window or in tmux without one.
    func canEndSession(_ conversation: Conversation) -> Bool {
        runningTerminal(for: conversation) != nil
            || runningTerminalInAnotherWindow(for: conversation) != nil
            || isRunningInTmux(conversation)
    }

    /// Closes the session's tabs in every window, ending the tmux sessions their CLIs run in, and ends the session's
    /// own tmux session when its CLI runs there without a tab. Each window ends its own tabs' tmux sessions, after the
    /// tmux commands it already queued, such as the rename that gave a new session's tmux session its name.
    func endSession(_ conversation: Conversation) {
        let host = conversation.host
        let windowStores = otherWindowStores + [self]
        var endedTmuxNames: Set<String> = []
        for store in windowStores {
            for tab in store.terminalSessions where tab.conversation?.id == conversation.id {
                if let tmuxName = tab.tmuxSessionName { endedTmuxNames.insert(tmuxName) }
                store.closeTerminal(tab.id, endingTmuxSession: true)
            }
        }
        let sessionTmuxName = TmuxSessionName.forConversation(conversation)
        if isRunningInTmux(conversation) && !endedTmuxNames.contains(sessionTmuxName) {
            endTmuxSession(named: sessionTmuxName, on: host)
            endedTmuxNames.insert(sessionTmuxName)
        }
        // Every window lists the host's tmux sessions until its next refresh, not just the one that ended them.
        for store in windowStores { store.tmuxSessionNamesByHost[host]?.subtract(endedTmuxNames) }
    }

    /// End sessions, from a multi-selection: ends each selected session whose CLI runs and skips the rest.
    func endSessions(_ conversations: [Conversation]) {
        for conversation in conversations where canEndSession(conversation) {
            endSession(conversation)
        }
    }

    /// Close and end session, from a tab's menu: closes the tab and stops its CLI without asking, as End session does
    /// from the session's row. A new session's tab not yet linked to its session stops only its own CLI.
    func closeTerminalEndingSession(_ id: UUID) {
        guard let tab = terminalSessions.first(where: { $0.id == id }) else { return }
        if let conversation = tab.conversation {
            endSession(conversation)
        } else {
            closeTerminal(id, endingTmuxSession: true)
        }
    }
}
