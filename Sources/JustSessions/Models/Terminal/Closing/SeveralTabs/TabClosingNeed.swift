import Foundation

/// What closing one tab stops, which decides what closing it asks: nothing, keeping its CLI running in tmux or ending
/// it, or stopping its CLI or shell.
enum TabClosingNeed: Equatable, Sendable {
    /// The tab hasn't started yet, so it closes as it is and leaves any tmux session it would attach to running.
    case nothingStarted
    /// Its CLI or shell already ended. Closing it also ends the dead tmux session that kept a failed CLI's output.
    case alreadyEnded
    /// Its CLI can keep running in tmux after the tab closes.
    case canKeepCLIRunning
    /// A plain terminal, whose shell stops with its tab.
    case plainTerminal
    /// A CLI that stops with its tab.
    case cliStopsWithTab

    init(isWaitingToBeShown: Bool, closingStopsNothing: Bool, canKeepCLIRunningAfterClose: Bool, isPlainTerminal: Bool) {
        if isWaitingToBeShown {
            self = .nothingStarted
        } else if closingStopsNothing {
            self = .alreadyEnded
        } else if canKeepCLIRunningAfterClose {
            self = .canKeepCLIRunning
        } else if isPlainTerminal {
            self = .plainTerminal
        } else {
            self = .cliStopsWithTab
        }
    }
}
