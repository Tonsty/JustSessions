import Foundation

/// Moving a tab, a split's two tabs, or a whole group's tabs from one window's tab bar to another's, as Chrome moves
/// tabs and groups dragged between windows. They leave their tab bar as closed tabs do, though a split goes whole, and
/// join the other bar among their group's tabs, or as a new group when that bar has none of their group.
extension TerminalTabStrip {
    /// Takes out `tabIDs`, whole units of one group as `movingUnits(inGroup:)` lists them: a tab in no split, a split's
    /// two tabs, or several, such as every tab of the group. Changes nothing and returns nil for any other set of tabs.
    mutating func takeOutForAnotherWindow(_ tabIDs: [UUID]) -> DetachedTabStripUnit? {
        guard let firstTab = tabs.first(where: { tabIDs.contains($0.id) }) else { return nil }
        let groupKey = groupKey(of: firstTab)
        let touchedUnits = movingUnits(inGroup: groupKey).filter { $0.contains(where: tabIDs.contains) }
        guard Set(touchedUnits.joined()) == Set(tabIDs) else { return nil }
        let leavingTabs = tabs.filter { tabIDs.contains($0.id) }
        let leavingSplits = splits.filter { split in leavingTabs.contains { split.contains($0.id) } }
        // Unlinked first, so taking out one of a split's tabs does not send the other back to its project's tabs.
        self = TerminalTabStrip(tabs: tabs, splits: splits.filter { !leavingSplits.contains($0) })
        for tab in leavingTabs { removeTab(tab.id) }
        return DetachedTabStripUnit(tabs: leavingTabs, splits: leavingSplits, groupKey: groupKey)
    }

    /// Puts tabs taken out of another window's tab bar in this one, together at `placement`, with their splits showing
    /// in their group.
    mutating func bringIn(_ unit: DetachedTabStripUnit, at placement: TabStripPlacement) {
        var reorderedTabs = tabs
        // Where a new tab of the group opens, then moved to its place.
        reorderedTabs.insert(
            contentsOf: unit.tabs,
            at: TerminalTabOrder.insertionIndex(forProjectKey: unit.groupKey, amongTabProjectKeys: groupKeys)
        )
        self = TerminalTabStrip(tabs: reorderedTabs, splits: splits + unit.splits)
        switch placement {
        case .amongGroupTabs(let place):
            moveTabs(unit.tabs.map(\.id), toPlaceInGroup: place)
        case .asNewGroup(let place):
            moveGroup(unit.groupKey, toPlace: place)
        }
    }
}
