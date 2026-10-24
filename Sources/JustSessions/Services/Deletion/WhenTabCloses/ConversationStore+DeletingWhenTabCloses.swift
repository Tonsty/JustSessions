import Foundation

/// Sessions started with **Delete the session when its tab closes** in the New session sheet. Ticking the box was the
/// question (PRD-26), so closing the tab deletes its session as Close and delete does, without asking again: from its
/// ×, ⌘W, its menu, or with other tabs. Closing its window, quitting, or disconnecting its host doesn't close the tab
/// on purpose, so the session stays until its tab is closed.
extension ConversationStore {
    /// The session the tab is linked to was started so, or, before the tab is linked, the tab was.
    func deletesSessionWhenClosed(_ tab: TerminalSession) -> Bool {
        guard let conversation = tab.conversation else { return tab.deletesSessionWhenClosed }
        return sessionsDeletedWhenTabCloses.isDeletedWhenTabCloses(conversationID: conversation.id)
    }

    /// **Keep session** in the tab's menu: closing the tab then asks as any tab's does, and the session stays.
    func keepSessionAfterClosing(_ tab: TerminalSession) {
        tab.deletesSessionWhenClosed = false
        guard let conversation = tab.conversation else {
            // The tab bar reads the tab's choice through the store, which does not see a tab's own changes.
            noteTabStateChanged()
            return
        }
        setDeletedWhenTabCloses(false, conversationIDs: [conversation.id])
    }

    /// Run as the tab links to a session. A new session's tab passes its choice to the first session it links to. A
    /// tab that follows its CLI to another session, as `/clear` or `/resume` moves it, keeps both: the other session
    /// may be one the tab didn't start.
    func carryDeletionWhenClosed(of tab: TerminalSession, from previousConversationID: String?) {
        guard let conversation = tab.conversation, conversation.id != previousConversationID else { return }
        if let previousConversationID {
            let previousWasDeletedWhenTabCloses = sessionsDeletedWhenTabCloses.isDeletedWhenTabCloses(
                conversationID: previousConversationID
            )
            guard previousWasDeletedWhenTabCloses else { return }
            tab.deletesSessionWhenClosed = false
            setDeletedWhenTabCloses(false, conversationIDs: [previousConversationID])
        } else if tab.deletesSessionWhenClosed {
            setDeletedWhenTabCloses(true, conversationIDs: [conversation.id])
        }
    }

    /// Closes the tab and deletes its session as Close and delete does: the session's tabs in every window close, its
    /// CLI ends, and the session is deleted once the CLI exits. A tab not linked yet has no session listed to delete,
    /// so its CLI only ends.
    func closeTabDeletingItsSession(_ id: UUID) {
        guard let tab = terminalSessions.first(where: { $0.id == id }) else { return }
        guard let conversation = tab.conversation.flatMap({ conversationIndex.conversation(withID: $0.id) }) else {
            // Its session was meant to go, so Reopen Closed Tab doesn't bring it back.
            closingTabsWithoutRemembering { closeTerminal(id, endingTmuxSession: true) }
            return
        }
        closeAndDelete(conversation)
    }
}
