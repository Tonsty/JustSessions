import Foundation
import Observation

/// Where a window's tab bar draws tabs dragged in from another window: as a group of their own among the groups, or
/// among their group's tabs, with a display for each group, so a drag there re-runs only that group. Also the tabs
/// leaving the bar for a window of their own, which the bar hides where they were until they go. See
/// `TabDragBetweenWindows`.
@MainActor
@Observable
final class TabBarDragDisplays {
    @ObservationIgnored let amongGroups = TabBarDragDisplay<String>()
    /// Tabs dragged off the bar while a window opens to carry them.
    var leavingTabIDs: Set<UUID> = []
    @ObservationIgnored private var amongTabsByGroupKey: [String: TabBarDragDisplay<[UUID]>] = [:]

    func amongTabs(ofGroup groupKey: String) -> TabBarDragDisplay<[UUID]> {
        if let display = amongTabsByGroupKey[groupKey] { return display }
        let display = TabBarDragDisplay<[UUID]>()
        amongTabsByGroupKey[groupKey] = display
        return display
    }
}
