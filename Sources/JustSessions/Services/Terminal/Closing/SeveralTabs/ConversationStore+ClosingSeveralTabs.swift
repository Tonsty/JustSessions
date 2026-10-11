import Foundation

/// Closing several tabs with one answer, such as every tab of a group from its menu. Each tab closes as it would on
/// its own: a tab that hasn't started leaves its tmux session alone, and an ended one ends its dead tmux session.
extension ConversationStore {
    /// What closing these tabs asks, with the choices saved with Don't ask again.
    func closingQuestion(
        forTabs ids: [UUID],
        tabCloseChoice: TabCloseChoice,
        plainTerminalCloseChoice: PlainTerminalCloseChoice
    ) -> SeveralTabsClosingQuestion {
        let needs = terminalSessions.filter { ids.contains($0.id) }.map(\.closingNeed)
        return SeveralTabsClosingQuestion(needs: needs, tabCloseChoice: tabCloseChoice, plainTerminalCloseChoice: plainTerminalCloseChoice)
    }

    /// Closes the tabs, the selected one last, so the tab shown next is one left open. With `endingTmuxSessions`, the
    /// CLIs tmux could keep running stop too.
    func closeTabs(_ ids: [UUID], endingTmuxSessions: Bool) {
        let tabsToClose = terminalSessions.filter { ids.contains($0.id) }
        let selectedLast = tabsToClose.filter { $0.id != selectedTerminalID } + tabsToClose.filter { $0.id == selectedTerminalID }
        for tab in selectedLast {
            switch tab.closingNeed {
            case .nothingStarted:
                closeTerminal(tab.id)
            case .canKeepCLIRunning:
                closeTerminal(tab.id, endingTmuxSession: endingTmuxSessions)
            case .alreadyEnded, .plainTerminal, .cliStopsWithTab:
                closeTerminal(tab.id, endingTmuxSession: true)
            }
        }
    }
}
