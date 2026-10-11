import Foundation

extension TerminalSession {
    /// What closing the tab stops, as it is now.
    var closingNeed: TabClosingNeed {
        TabClosingNeed(
            isWaitingToBeShown: isWaitingToBeShown,
            closingStopsNothing: closingStopsNothing,
            canKeepCLIRunningAfterClose: canKeepCLIRunningAfterClose,
            isPlainTerminal: isPlainTerminal
        )
    }
}
