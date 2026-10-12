import Foundation

/// A tab dragged onto the terminals and let go there shows in a split view, on the side it was let go on; see
/// `TerminalSplitDropArea` for the sides and `TabDragBetweenWindows` for the drag.
extension ConversationStore {
    /// Whether tabs dragged here, from this window's tab bar or another's, can show in a split: one tab in no split,
    /// beside a selected tab other than itself. A split's two tabs drag together, and a split view shows two panes.
    func canShowDroppedTabsInSplit(_ tabIDs: [UUID]) -> Bool {
        guard tabIDs.count == 1, let tabID = tabIDs.first, let selectedTerminalID, tabID != selectedTerminalID else { return false }
        return split(containing: tabID) == nil
    }

    /// Shows the tab, open here in no split, on `side` of a split view, and selects it: beside the selected tab in a new
    /// split, or, while the selected tab is in a split, in place of that split's tab on `side`, as Move tab into split
    /// view does.
    func showDroppedTabInSplit(_ tabID: UUID, on side: TerminalSplit.Side) {
        guard canShowDroppedTabsInSplit([tabID]) else { return }
        if shownSplit != nil {
            moveIntoShownSplit(tabID, swappingWith: side)
        } else {
            splitSelectedTerminal(with: tabID)
            // The tab joins on the side it came from in the tab bar.
            if let split = split(containing: tabID), sides(of: split)?.side(of: tabID) != side {
                reverseSplit(split.id)
            }
        }
        selectTerminal(tabID)
    }
}
