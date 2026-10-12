import SwiftUI

/// A project's tab group's menu, from its label in the tab bar or its heading in Open tabs: what a project's menu
/// offers for its folder, starting with New session, whose tab opens at the end of the group; collapsing the group or
/// every group; then closing the group's tabs.
struct TabGroupMenuItems: View {
    let store: ConversationStore
    let projectKey: String
    let projectDisplayName: String
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void
    let allGroups: AllTabGroupsCollapsing
    let onCloseTabs: () -> Void

    var body: some View {
        ProjectFolderMenuItems(
            store: store,
            location: ProjectLocation(key: projectKey),
            projectDisplayName: projectDisplayName,
            onNewSession: { store.launchNewSessionFromProject(provider: $0, projectPath: projectKey) }
        )
        Divider()
        Button(
            isCollapsed ? "Expand group" : "Collapse group",
            systemImage: isCollapsed ? "chevron.right" : "chevron.left",
            action: onToggleCollapsed
        )
        AllTabGroupsCollapseMenuItems(allGroups: allGroups)
        Divider()
        Button("Close all tabs in group…", systemImage: "xmark", role: .destructive, action: onCloseTabs)
    }
}
