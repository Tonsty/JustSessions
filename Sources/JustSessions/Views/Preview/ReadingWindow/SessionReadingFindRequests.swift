import Observation

/// Asks a reading window's reader to open Find, as ⌘F in a tab linked to the session does; see `TerminalFindTarget`.
@MainActor
@Observable
final class SessionReadingFindRequests {
    /// Goes up with each request; 0 until the first.
    private(set) var revision = 0

    func request() {
        revision += 1
    }
}
