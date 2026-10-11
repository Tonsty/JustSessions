import Foundation

extension ConversationStore {
    /// Whether Back or Forward can show `location` in this window: its tab is still open here, or its session is one
    /// the sidebar lists under its filters now, or a subagent's session. A session the filters hide is passed over,
    /// as the sidebar keeps only listed sessions selected.
    func canShow(_ location: WorkspaceLocation, listedConversationIDs: Set<String>) -> Bool {
        switch location {
        case .tab(let tabID):
            terminalSessions.contains { $0.id == tabID }
        case .conversation(let conversationID):
            listedConversationIDs.contains(conversationID) || subagentIndex.subagent(withID: conversationID) != nil
        }
    }

    /// Whether `location` and `previous` are the two tabs of one split, which shows both while either is selected.
    func areTabsOfOneSplit(_ previous: WorkspaceLocation?, _ location: WorkspaceLocation) -> Bool {
        guard case .tab(let previousTabID)? = previous, case .tab(let tabID) = location, previousTabID != tabID else {
            return false
        }
        return split(containing: tabID)?.contains(previousTabID) == true
    }

    /// What Back's and Forward's menus call `location`: its tab's title, or its session's. Nil once it is gone.
    func title(of location: WorkspaceLocation) -> String? {
        switch location {
        case .tab(let tabID):
            terminalSessions.first { $0.id == tabID }?.displayTitle
        case .conversation(let conversationID):
            conversation(withID: conversationID).map(title(for:))
        }
    }
}
