import SwiftUI

/// A tab's menu, from a right-click on it in the tab bar or on its row in Open tabs. A session's tab starts with
/// Rename, then sharing and finding its session, in the order its sidebar row's menu has them; then the split view
/// entries; then closing it. New session is about the tab's project, so it is in the group's menu instead. Pinning is
/// left to the session's row: a pinned session stays at the top of the sidebar, which a tab has nothing to do with. A
/// tab's terminal offers the same items after its text's; see `TerminalContextMenu`.
struct TerminalTabMenuItems: View {
    @ObservedObject var store: ConversationStore
    @ObservedObject var tab: TerminalSession
    let onRename: (Conversation) -> Void
    /// Asks what to do with a tab's CLI, as its × does; also for the split entries that close one of its views.
    let onCloseTab: (UUID) -> Void

    var body: some View {
        if !tab.isPlainTerminal {
            sessionItems
            Divider()
        }
        TerminalTabSplitMenuItems(splitMenu: store.splitMenu(forTab: tab.id)) { action in
            store.performSplitAction(action, fromTab: tab.id, closeTab: onCloseTab)
        }
        Button(tab.isPlainTerminal ? "Close terminal…" : "Close Tab…", systemImage: "xmark", role: .destructive) {
            onCloseTab(tab.id)
        }
    }

    /// A new session's tab can't be renamed or shared until it is linked to the session its CLI writes.
    @ViewBuilder private var sessionItems: some View {
        Button("Rename", systemImage: "pencil") {
            if let conversation = tab.conversation { onRename(conversation) }
        }
        .disabled(tab.conversation == nil)
        if let conversation = tab.conversation {
            Divider()
            ConversationSharingMenuItems(selections: [ConversationExportSelection(conversation: conversation, title: tab.displayTitle)])
            Button("Copy session ID", systemImage: "doc.on.doc") {
                SessionLocationActions.copySessionID(conversation)
            }
            if conversation.host == .thisMac {
                Button("Reveal session file in Finder", systemImage: "doc.text.magnifyingglass") {
                    SessionLocationActions.revealSessionFile(conversation)
                }
            }
        }
    }
}
