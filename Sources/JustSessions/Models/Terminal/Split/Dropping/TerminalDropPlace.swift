/// Where a tab or session dragged onto a window's terminals shows once let go.
enum TerminalDropPlace: Equatable {
    /// On this side of a split view: the half of a new split beside the selected tab, or the shown split's pane.
    case split(TerminalSplit.Side)
    /// Filling the terminals, as the window shows no tab to split with.
    case wholeArea
}
