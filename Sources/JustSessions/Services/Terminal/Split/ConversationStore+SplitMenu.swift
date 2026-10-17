import Foundation

/// The split entries a tab's menus offer, in the tab bar and in its terminal, and what each one does.
extension ConversationStore {
    /// The split entries Chrome's tab menu offers for the tab: a tab in a split, or beside a split chooser, arranges it;
    /// any other tab can open in a new split with the selected tab while that is in none, or take a place in its split
    /// or beside its chooser while it is in one.
    func splitMenu(forTab tabID: UUID) -> TerminalTabSplitMenu? {
        if isInSplitOrChooser(tabID) { return .arrangeSplit }
        guard let selectedTerminalID else { return nil }
        if isInSplitOrChooser(selectedTerminalID) { return .moveIntoShownSplit }
        guard tabID == selectedTerminalID else { return .newSplitWithSelectedTab }
        let candidates = terminalSessions
            .filter { $0.id != tabID && !isInSplitOrChooser($0.id) }
            .map { TerminalTabSplitCandidate(session: $0, projectDisplayName: projectDisplayName(forProjectPath: $0.projectDirectoryKey)) }
        return .addTabToNewSplit(candidates: candidates)
    }

    /// Acts on the tab's split entry. The views a split entry closes go through `closeTab`, the same close request as
    /// their ×; a split chooser closes at once, as it runs nothing. Separating a tab from its chooser closes the chooser.
    func performSplitAction(_ action: TerminalTabSplitAction, fromTab tabID: UUID, closeTab: (UUID) -> Void) {
        switch action {
        case .newSplitWithSelectedTab:
            splitSelectedTerminal(with: tabID)
        case .addToNewSplit(let otherTabID):
            splitSelectedTerminal(with: otherTabID)
        case .moveIntoShownSplit(let side):
            moveIntoShownSplitView(tabID, on: side)
        case .separateViews:
            if let split = split(containing: tabID) {
                separateSplit(split.id)
            } else if let chooser = splitChooser(beside: tabID) {
                closeSplitChooser(chooser.id)
            }
        case .closeView(let side):
            if let split = split(containing: tabID), let sides = sides(of: split) {
                closeTab(sides.tabID(on: side))
            } else if let chooser = splitChooser(beside: tabID) {
                if side == chooser.side { closeSplitChooser(chooser.id) } else { closeTab(chooser.tabID) }
            }
        case .reverseViews:
            if let split = split(containing: tabID) {
                reverseSplit(split.id)
            } else if let chooser = splitChooser(beside: tabID) {
                reverseSplitChooser(chooser.id)
            }
        }
    }
}
