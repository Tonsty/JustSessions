import Foundation

/// Closing several tabs with one answer, such as every tab of a group from its menu. Each tab closes as it would on
/// its own: a tab that hasn't started leaves its tmux session alone, and an ended one ends its dead tmux session.
extension ConversationStore {
    /// What closing these tabs asks, with the choices saved with Don't ask again, each tab's for its own host.
    func closingQuestion(
        forTabs ids: [UUID],
        tabCloseChoices: TabCloseChoicesByHost,
        plainTerminalCloseChoice: PlainTerminalCloseChoice
    ) -> SeveralTabsClosingQuestion {
        let tabs = terminalSessions.filter { ids.contains($0.id) }
            .map { (need: $0.closingNeed, tabCloseChoice: tabCloseChoices.choice(for: $0.host)) }
        return SeveralTabsClosingQuestion(tabs: tabs, plainTerminalCloseChoice: plainTerminalCloseChoice)
    }

    /// Closes the tabs, the selected one last, so the tab shown next is one left open. With `endingTmuxSessions`, the
    /// CLIs tmux could keep running stop too.
    func closeTabs(_ ids: [UUID], endingTmuxSessions: Bool) {
        closeTabs(ids) { _ in endingTmuxSessions }
    }

    /// Closes the tabs without asking: each CLI tmux could keep running ends or keeps running as its host's saved
    /// choice says.
    func closeTabs(_ ids: [UUID], as tabCloseChoices: TabCloseChoicesByHost) {
        closeTabs(ids) { tabCloseChoices.choice(for: $0).endsTmuxSessionWithoutAsking ?? true }
    }

    private func closeTabs(_ ids: [UUID], endingTmuxSessionOn endsTmuxSession: (SessionHost) -> Bool) {
        let tabsToClose = terminalSessions.filter { ids.contains($0.id) }
        let selectedLast = tabsToClose.filter { $0.id != selectedTerminalID } + tabsToClose.filter { $0.id == selectedTerminalID }
        for tab in selectedLast {
            switch tab.closingNeed {
            case .nothingStarted:
                closeTerminal(tab.id)
            case .canKeepCLIRunning:
                closeTerminal(tab.id, endingTmuxSession: endsTmuxSession(tab.host))
            case .alreadyEnded, .plainTerminal, .cliStopsWithTab:
                closeTerminal(tab.id, endingTmuxSession: true)
            }
        }
    }
}
