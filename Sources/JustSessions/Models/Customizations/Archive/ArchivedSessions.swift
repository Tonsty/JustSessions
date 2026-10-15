import Foundation

/// Sessions archived from the sidebar, keyed by `Conversation.id`. Archiving only hides a session from the Projects
/// list until the filter menu's Show archived is on; its file, name, and pin are kept.
struct ArchivedSessions: Equatable {
    static let userDefaultsKey = "archivedConversationIDs"

    private(set) var archivedConversationIDs: Set<String>

    init(archivedConversationIDs: Set<String> = []) {
        self.archivedConversationIDs = archivedConversationIDs
    }

    static func load(from userDefaults: UserDefaults) -> ArchivedSessions {
        ArchivedSessions(archivedConversationIDs: Set(userDefaults.stringArray(forKey: userDefaultsKey) ?? []))
    }

    /// Sorted, so the same archive saves the same value.
    func save(to userDefaults: UserDefaults) {
        userDefaults.set(archivedConversationIDs.sorted(), forKey: Self.userDefaultsKey)
    }

    func isArchived(conversationID: String) -> Bool {
        archivedConversationIDs.contains(conversationID)
    }

    mutating func setArchived(_ isArchived: Bool, conversationIDs: some Sequence<String>) {
        if isArchived {
            archivedConversationIDs.formUnion(conversationIDs)
        } else {
            archivedConversationIDs.subtract(conversationIDs)
        }
    }
}
