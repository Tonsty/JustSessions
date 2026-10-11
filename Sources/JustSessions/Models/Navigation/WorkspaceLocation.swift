import Foundation

/// What a workspace window's main area shows: a tab's terminal, or, with no tab selected, one session's conversation.
/// Back and Forward move between them, as Chrome's move between the pages a tab showed.
enum WorkspaceLocation: Hashable {
    case tab(UUID)
    case conversation(String)

    /// The selected tab, or else the session selected alone in the sidebar. Nil while the area shows neither, as with
    /// several sessions selected or none.
    static func shown(selectedTabID: UUID?, onlySelectedConversationID: String?) -> WorkspaceLocation? {
        if let selectedTabID { return .tab(selectedTabID) }
        return onlySelectedConversationID.map(WorkspaceLocation.conversation)
    }
}
