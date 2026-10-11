import Foundation

/// Shows a session whose CLI wants you back, for a clicked notification or a row of a window's notification bell.
extension WorkspaceWindowRegistry {
    /// Selects the session's tab in the window that has it, or else reattaches to its CLI in tmux in
    /// `reattachingStore`'s window, or the first window when nil, and brings that window forward.
    func showSession(wantingAttention source: SessionAttentionSource, reattachingIn reattachingStore: ConversationStore? = nil) {
        if let store = stores.first(where: { $0.showTab(notifiedAbout: source) }) {
            bringForward(store)
        } else if let store = reattachingStore ?? stores.first {
            store.reattach(notifiedAbout: source)
            bringForward(store)
        }
    }
}
