import SwiftUI

/// The menu of the space around the tab groups, in the tab bar or in Open tabs, with no tab or group under the
/// pointer: a new session, from the sheet ⌘N opens, and collapsing or expanding every group.
struct TabGroupsBackgroundMenuItems: View {
    let onNewSession: () -> Void
    let allGroups: AllTabGroupsCollapsing

    var body: some View {
        Button("New session…", systemImage: "plus", action: onNewSession)
        Divider()
        AllTabGroupsCollapseMenuItems(allGroups: allGroups)
    }
}
