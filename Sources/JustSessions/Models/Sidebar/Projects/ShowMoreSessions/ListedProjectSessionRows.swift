import Foundation

/// A project's rows as the sidebar lists them: its pinned sessions and new sessions' tabs, then its other sessions up to
/// a limit (see `ProjectSessionRowLimits`), with how many it leaves for "Show N more".
struct ListedProjectSessionRows {
    let rows: [ProjectSessionRow]
    /// The project's sessions below the listed ones.
    let hiddenSessionCount: Int

    /// `sessionLimit` caps the sessions that are not pinned; nil lists them all. `conversations` lists pinned sessions
    /// first, as `ProjectConversationGroup` does.
    init(
        conversations: [Conversation],
        pendingNewSessions: [PendingNewSession],
        pinnedItems: PinnedItems,
        sessionLimit: Int?
    ) {
        let pinnedSessionCount = Self.pinnedSessionCount(in: conversations, pinnedItems: pinnedItems)
        let otherSessionCount = conversations.count - pinnedSessionCount
        let listedOtherSessionCount = ProjectSessionRowLimits.listedSessionCount(of: otherSessionCount, limit: sessionLimit)
        rows = ProjectSessionRow.ordered(
            conversations: Array(conversations.prefix(pinnedSessionCount + listedOtherSessionCount)),
            pendingNewSessions: pendingNewSessions,
            pinnedItems: pinnedItems
        )
        hiddenSessionCount = otherSessionCount - listedOtherSessionCount
    }

    /// The listed sessions' ids, top to bottom, leaving out new sessions' tabs.
    var conversationIDs: [String] {
        rows.compactMap { row in
            if case .conversation(let conversation) = row { conversation.id } else { nil }
        }
    }

    /// The place of a session hidden below the listed ones among the sessions the limit counts, for
    /// `ProjectSessionRowLimits.reveal`; nil when it is listed or not in `conversations`.
    static func hiddenPlace(
        of conversationID: String,
        in conversations: [Conversation],
        pinnedItems: PinnedItems,
        sessionLimit: Int?
    ) -> Int? {
        guard let index = conversations.firstIndex(where: { $0.id == conversationID }) else { return nil }
        let pinnedSessionCount = Self.pinnedSessionCount(in: conversations, pinnedItems: pinnedItems)
        let place = index - pinnedSessionCount
        let listedOtherSessionCount = ProjectSessionRowLimits.listedSessionCount(
            of: conversations.count - pinnedSessionCount, limit: sessionLimit
        )
        return place >= listedOtherSessionCount ? place : nil
    }

    private static func pinnedSessionCount(in conversations: [Conversation], pinnedItems: PinnedItems) -> Int {
        conversations.prefix { pinnedItems.isPinned(conversationID: $0.id) }.count
    }
}
