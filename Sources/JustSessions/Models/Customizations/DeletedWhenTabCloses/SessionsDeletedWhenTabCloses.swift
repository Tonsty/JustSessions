import Foundation

/// Sessions started with **Delete the session when its tab closes** in the New session sheet, keyed by
/// `Conversation.id`. Closing the session's tab deletes it without asking again; ticking the box was the question.
/// Kept in settings so a tab reopened at launch, or moved to another window, still deletes its session when it closes.
struct SessionsDeletedWhenTabCloses: Equatable {
    static let userDefaultsKey = "conversationIDsDeletedWhenTabCloses"

    private(set) var conversationIDs: Set<String>

    init(conversationIDs: Set<String> = []) {
        self.conversationIDs = conversationIDs
    }

    static func load(from userDefaults: UserDefaults) -> SessionsDeletedWhenTabCloses {
        SessionsDeletedWhenTabCloses(conversationIDs: Set(userDefaults.stringArray(forKey: userDefaultsKey) ?? []))
    }

    /// Sorted, so the same sessions save the same value.
    func save(to userDefaults: UserDefaults) {
        userDefaults.set(conversationIDs.sorted(), forKey: Self.userDefaultsKey)
    }

    func isDeletedWhenTabCloses(conversationID: String) -> Bool {
        conversationIDs.contains(conversationID)
    }

    mutating func setDeletedWhenTabCloses(_ isDeleted: Bool, conversationIDs changedIDs: some Sequence<String>) {
        if isDeleted {
            conversationIDs.formUnion(changedIDs)
        } else {
            conversationIDs.subtract(changedIDs)
        }
    }
}
