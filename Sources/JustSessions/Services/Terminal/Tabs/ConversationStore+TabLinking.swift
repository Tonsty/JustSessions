import Foundation

extension ConversationStore {
    /// Links the tab to the session its CLI is in: a new session's tab once the session is known, or a tab whose CLI
    /// moved to another session. The tab takes the session's title, its tmux session the session's name, and the
    /// session's row in the sidebar, Resume, and the next launch find the tab.
    func link(_ session: TerminalSession, to conversation: Conversation) {
        // A session the CLI moved to may be as untitled as a new session's; see new session discovery.
        if session.conversation?.id != conversation.id { session.titleRefreshCount = 0 }
        let previousConversationID = session.conversation?.id
        session.synchronize(conversation: conversation, displayTitle: title(for: conversation))
        carryDeletionWhenClosed(of: session, from: previousConversationID)
        adoptSessionTmuxName(for: session)
        // Sidebar rows look up open terminals through the store, which does not see a tab's own changes; other
        // windows' rows look up this window's.
        persistOpenTabs()
        noteTabStateChanged()
        windowRegistry.tabsChanged(in: self)
    }
}
