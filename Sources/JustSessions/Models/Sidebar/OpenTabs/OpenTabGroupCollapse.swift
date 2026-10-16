import Foundation

/// Which project groups in the sidebar's Open tabs list are collapsed. Groups start expanded, as every row under them
/// is an open tab. A search shows every match without changing which groups are collapsed.
struct OpenTabGroupCollapse: Equatable {
    private(set) var collapsedProjectKeys: Set<String> = []

    func isCollapsed(_ projectKey: String, whileSearching isSearching: Bool) -> Bool {
        !isSearching && collapsedProjectKeys.contains(projectKey)
    }

    /// The tabs whose rows show, in list order: every tab of a group not collapsed. A Shift-click range runs over these.
    func tabsInSight<Tab>(of groups: [TerminalTabGroup<Tab>], whileSearching isSearching: Bool) -> [Tab] {
        groups.filter { !isCollapsed($0.projectDirectoryKey, whileSearching: isSearching) }.flatMap(\.tabs)
    }

    mutating func toggle(_ projectKey: String) {
        if collapsedProjectKeys.remove(projectKey) == nil {
            collapsedProjectKeys.insert(projectKey)
        }
    }

    /// Opens the group, such as when one of its tabs is selected elsewhere, so the selected row shows.
    mutating func expand(_ projectKey: String) {
        collapsedProjectKeys.remove(projectKey)
    }

    /// Collapses every one of the groups, from Collapse all groups.
    mutating func collapse(_ projectKeys: [String]) {
        collapsedProjectKeys.formUnion(projectKeys)
    }

    mutating func expandAll() {
        collapsedProjectKeys.removeAll()
    }

    /// Forgets groups that are no longer open, so a project whose last tab closed opens expanded next time.
    mutating func keepOnly(_ openProjectKeys: [String]) {
        collapsedProjectKeys.formIntersection(openProjectKeys)
    }
}
