import SwiftUI

/// Collapsing or expanding every tab group at once, in the tab bar or in Open tabs, each of which keeps its own
/// collapsed groups.
struct AllTabGroupsCollapsing {
    /// Some group is still expanded.
    let canCollapseAll: Bool
    /// Some group is collapsed.
    let canExpandAll: Bool
    let collapseAll: () -> Void
    let expandAll: () -> Void
}

/// Collapse all groups and Expand all groups, in a group's menu and the menu of the space around the groups. Each is
/// disabled while it would change nothing.
struct AllTabGroupsCollapseMenuItems: View {
    let allGroups: AllTabGroupsCollapsing

    var body: some View {
        Button("Collapse all groups", systemImage: "chevron.left.2", action: allGroups.collapseAll)
            .disabled(!allGroups.canCollapseAll)
        Button("Expand all groups", systemImage: "chevron.right.2", action: allGroups.expandAll)
            .disabled(!allGroups.canExpandAll)
    }
}
