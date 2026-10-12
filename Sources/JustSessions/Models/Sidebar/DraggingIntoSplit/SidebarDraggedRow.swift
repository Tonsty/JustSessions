import Foundation

/// A sidebar row dragged onto its window's terminals, which shows what it lists there once let go; see
/// `ConversationStore.dropPlace(for:onSide:)`.
enum SidebarDraggedRow: Equatable {
    /// A session under its project in the project list.
    case session(Conversation)
    /// A tab in the list of open tabs.
    case openTab(UUID)
}
