import Foundation

/// Resuming from the sidebar, the preview, a drop on the terminals, or Move to. Resuming asks for a session back, so an
/// archived one leaves the archive, as starting a session in an archived folder restores its project. Only what you
/// resume counts: tabs reopened at launch, a tab moved here from another window, and a click that shows a running
/// session's tab leave the archive as it is.
extension ConversationStore {
    func resume(_ conversation: Conversation, appendedArguments: [String] = []) {
        unarchiveResumableSessions([conversation])
        launch(conversation, action: .resume, appendedArguments: appendedArguments)
    }

    func resume(_ conversations: [Conversation]) {
        unarchiveResumableSessions(conversations)
        launch(conversations, action: .resume)
    }

    /// A session that can't be resumed, such as one whose folder is gone, stays archived.
    func unarchiveResumableSessions(_ conversations: [Conversation]) {
        setArchived(false, conversations: conversations.filter { canLaunch($0, action: .resume) })
    }
}
