import Foundation

/// Leaves archived sessions out of the Projects list, as it does by default, or lists them with the others.
enum SessionArchiveFilter: Hashable {
    case hideArchived
    case showArchived

    func includes(_ conversation: Conversation, archived: ArchivedSessions) -> Bool {
        self == .showArchived || !archived.isArchived(conversationID: conversation.id)
    }
}
