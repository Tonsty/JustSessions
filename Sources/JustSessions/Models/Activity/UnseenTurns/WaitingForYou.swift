import Foundation

/// Whether a running CLI waits on you: stopped in the middle of a turn for your answer, or done with a turn you have
/// not seen. One at work, or done with a turn you saw, does not.
enum WaitingForYou {
    static func includes(activity: CLIActivity?, hasUnseenFinishedTurn: Bool) -> Bool {
        reason(activity: activity, hasUnseenFinishedTurn: hasUnseenFinishedTurn) != nil
    }

    /// Why the CLI waits on you; nil when it does not.
    static func reason(activity: CLIActivity?, hasUnseenFinishedTurn: Bool) -> SessionAttentionReason? {
        switch activity {
        case .needsInput(let reason): .needsInput(reason: reason)
        case .working: nil
        // A CLI that tells nothing for a moment still finished the turn it was marked for.
        case .idle, nil: hasUnseenFinishedTurn ? .finishedTurn : nil
        }
    }
}
