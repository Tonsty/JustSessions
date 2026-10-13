import Foundation

struct SessionDeletionPlan {
    let deletableConversations: [Conversation]
    let openTerminalCount: Int
    /// Deletable sessions whose tabs close and CLIs end first, in a plan made for Close and delete.
    var cliEndingCount = 0
    /// Subagent sessions, at any depth, that go with the deletable sessions; see `deletesSubagentsWithSession`.
    var deletedSubagentCount = 0
    /// Subagent sessions that stay on disk when the sessions that started them are deleted.
    var keptSubagentCount = 0

    var hasDeletableConversations: Bool { !deletableConversations.isEmpty }
}
