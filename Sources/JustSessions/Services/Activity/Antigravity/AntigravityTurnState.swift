import Foundation

/// Whether Antigravity is in the middle of a turn, as its conversation database (`conversations/<id>.db`) records
/// it. Antigravity adds a turn's steps to `steps` as it goes, starting with your prompt, and one row to
/// `executor_metadata` when the turn (an "execution") ends, which names its last step. Steps after the last ended
/// execution belong to the one under way. See `AntigravityTurnStateReader`.
enum AntigravityTurnState: Equatable, Sendable {
    /// A turn started, at its first step's time when known, and has not ended. `isWaitingForApproval` while one of
    /// its steps waits for you to allow it, such as a command Antigravity asks to run.
    case inTurn(startedAt: Date?, isWaitingForApproval: Bool)
    /// The last turn ended, or none has started.
    case betweenTurns
}
