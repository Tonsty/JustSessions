import SwiftUI

/// Selecting several Open tabs rows to close together, as sessions are selected in Projects: ⌘-click toggles a row and
/// Shift-click selects a range of the rows in sight. While nothing is selected, the shown tab's row counts as selected,
/// so a ⌘- or Shift-click adds to it. A plain click shows its tab and clears the selection.
extension SidebarOpenTabsView {
    /// The rows in list order, leaving out the tabs of collapsed groups, which a Shift-click range skips.
    var visibleTabIDs: [UUID] {
        let groups = TerminalTabGroup.groups(of: matchingTabs, projectDirectoryKey: \.projectDirectoryKey)
        return groupCollapse.tabsInSight(of: groups, whileSearching: isSearching).map(\.id)
    }

    /// While rows are selected, they are the ones highlighted, so the rows lit are the tabs closing them would close.
    func isHighlighted(_ tabID: UUID) -> Bool {
        selection.isEmpty ? store.selectedTerminalID == tabID : selection.contains(tabID)
    }

    func handleRowClick(_ tabID: UUID) {
        let modifiers = NSEvent.modifierFlags
        guard modifiers.contains(.shift) || modifiers.contains(.command) else {
            onSelectTab(tabID)
            return
        }
        isListFocused = true
        let visibleTabIDs = visibleTabIDs
        let shownTabID = store.selectedTerminalID.flatMap { visibleTabIDs.contains($0) ? $0 : nil }
        selection.selectShownTabWhileNothingIsSelected(shownTabID)
        if modifiers.contains(.shift) {
            selection.selectRange(to: tabID, in: visibleTabIDs)
        } else {
            selection.toggle(tabID)
        }
    }
}
