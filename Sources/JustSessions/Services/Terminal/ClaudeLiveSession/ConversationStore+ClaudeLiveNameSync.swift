import Foundation

/// Keeps names chosen with `/rename` inside a running Claude Code tab in step with the tab title
/// and the matching sidebar entry, without waiting for a full refresh. On this Mac it reads the registry; on an SSH
/// host the relay carries it in the tab's title (`RemoteClaudeSessionTitle`). A tab whose CLI moved to another
/// session, as with `/clear`, follows it first; see `followClaudeSessionSwitch`. Where the registry leaves the name
/// out, the transcript still has it; see `followAppendedSessionNames` on this Mac and the relay on SSH hosts.
extension ConversationStore {
    func startClaudeLiveNameSync(interval: Duration = .seconds(1)) {
        runPeriodically(every: interval) { $0.synchronizeClaudeLiveNames() }
    }

    func synchronizeClaudeLiveNames(registry: ClaudeLiveSessionRegistry = ClaudeLiveSessionRegistry()) {
        for session in terminalSessions where session.provider == .claude && !session.hasExited {
            let record = session.host == .thisMac
                ? registry.record(forProcessID: session.cliProcessID)
                : session.terminalTitle.flatMap(RemoteClaudeSessionTitle.record(inTerminalTitle:))
            guard let record else { continue }
            followClaudeSessionSwitch(of: session, to: record.sessionID)
            applyLiveName(from: record, to: session)
        }
    }

    func applyLiveName(from record: ClaudeLiveSessionRecord, to session: TerminalSession) {
        guard let liveName = record.userChosenName else { return }
        // Until the tab follows its CLI to a session `/clear` started, which waits for a refresh to list that session,
        // the name belongs to a session the tab does not show.
        if let linkedConversation = session.conversation, linkedConversation.sessionID != record.sessionID { return }
        applyChosenName(liveName, toSessionID: record.sessionID, provider: .claude, shownIn: session)
    }
}
