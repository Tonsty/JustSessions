import SwiftUI

/// A session a subagent ran in, under the session that started it. Clicking it reads it in the preview; it is never
/// resumed, renamed, pinned, or deleted on its own. The age gives way to a ⋯ while the pointer is over the row.
struct SidebarSubagentRow: View {
    @ObservedObject var store: ConversationStore
    let row: SidebarSubagentRows.Row
    let isSelected: Bool
    let isExpanded: Bool
    let onClick: (Conversation) -> Void
    let onToggleSubagents: () -> Void

    @State private var isHovered = false
    /// Holds the pointer-over state for a test; nil follows `onHover` as in use.
    var isHoveredForTests: Bool? = nil
    private var hovered: Bool { isHoveredForTests ?? isHovered }

    var body: some View {
        let conversation = row.conversation
        let title = store.title(for: conversation)

        Button {
            onClick(conversation)
        } label: {
            SidebarSessionRowLayout(provider: conversation.provider, isSelected: isSelected, indentLevel: row.depth) {
                Text(title)
            } trailing: {
                ZStack(alignment: .trailing) {
                    SessionAgeLabel(lastActivity: conversation.updatedAt)
                        .opacity(hovered ? 0 : 1)
                    SidebarRowMoreActionsLabel()
                        .hidden()
                }
            }
        }
        .buttonStyle(ThemePlainButtonStyle(showsHover: false))
        .help("\(title) · \(conversation.provider.rawValue) subagent · \(SidebarSessionDateText.shared.text(for: conversation.updatedAt))")
        .accessibilityLabel("\(title), \(conversation.provider.rawValue) subagent")
        .overlay(alignment: .leading) {
            if row.subagentCount > 0 {
                SubagentDisclosureButton(
                    isExpanded: isExpanded,
                    subagentCount: row.subagentCount,
                    sessionTitle: title,
                    indentLevel: row.depth,
                    action: onToggleSubagents
                )
            }
        }
        .overlay(alignment: .trailing) {
            // In the view tree only while the pointer is over the row; see `SidebarProjectRow`.
            if hovered {
                SidebarRowMoreActionsMenu(accessibilityLabel: "More actions for \(title)") {
                    menuItems
                }
                .padding(.trailing, SidebarSessionRowMetrics.trailingPadding)
            }
        }
        .background(
            SidebarRowBackground(isSelected: isSelected, isHovered: hovered, selectionProvider: conversation.provider)
        )
        .onHover { isHovered = $0 }
        .contextMenu { menuItems }
    }

    private var menuItems: some View {
        SessionManagementMenuItems(store: store, conversation: row.conversation, onRename: {}, onDelete: {})
    }
}
