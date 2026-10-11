import Foundation

/// What closing several tabs at once asks, such as a tab group's: one question for them all, or none when every tab
/// would close without asking on its own, by itself or by the choices saved with Don't ask again.
enum SeveralTabsClosingQuestion: Equatable, Sendable {
    /// Close them all without asking. CLIs in tmux end or keep running as the saved choice says.
    case closeWithoutAsking(endingTmuxSessions: Bool)
    /// Keep running or End sessions, for the CLIs tmux can keep running. With `alsoStopsOthers`, other tabs' CLIs or
    /// shells stop whichever is picked.
    case keepOrEndCLIs(alsoStopsOthers: Bool)
    /// Close the tabs, stopping their CLIs and shells, or Cancel.
    case stopEverything

    init(needs: [TabClosingNeed], tabCloseChoice: TabCloseChoice, plainTerminalCloseChoice: PlainTerminalCloseChoice) {
        let savedTmuxChoice = tabCloseChoice.endsTmuxSessionWithoutAsking
        let hasCLIsToKeep = needs.contains(.canKeepCLIRunning)
        let stopsOthersAskingFirst = needs.contains(.cliStopsWithTab)
            || (needs.contains(.plainTerminal) && plainTerminalCloseChoice == .askEachTime)
        if hasCLIsToKeep, savedTmuxChoice == nil || stopsOthersAskingFirst {
            let stopsOthers = needs.contains(.cliStopsWithTab) || needs.contains(.plainTerminal)
            self = .keepOrEndCLIs(alsoStopsOthers: stopsOthers)
        } else if stopsOthersAskingFirst {
            self = .stopEverything
        } else {
            self = .closeWithoutAsking(endingTmuxSessions: savedTmuxChoice ?? true)
        }
    }
}
