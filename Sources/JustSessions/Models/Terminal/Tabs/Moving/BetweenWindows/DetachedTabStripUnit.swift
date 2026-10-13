import Foundation

/// Tabs taken out of one window's tab bar to go into another's: a tab, a split's two tabs, or a whole group's tabs,
/// dragged by its label. A split goes whole, so its panes stay side by side.
struct DetachedTabStripUnit: Equatable {
    /// In tab bar order, so a split's left pane's tab comes first.
    let tabs: [TerminalTabStrip.Tab]
    /// The splits linking the tabs in pairs, none for a tab on its own.
    let splits: [TerminalSplit]
    /// The group the tabs show in once in another window's tab bar: a split's, which is a group of its own for a
    /// split across projects, or else the tabs' project.
    let groupKey: String
}
