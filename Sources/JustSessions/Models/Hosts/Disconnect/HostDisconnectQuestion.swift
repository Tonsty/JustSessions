import Foundation

/// What Disconnect asks before closing the host's open tabs, in every window, as closing them together asks; see
/// `SeveralTabsClosingQuestion`. Nothing is asked when no tab is open on the host, or when each would close without
/// asking on its own.
struct HostDisconnectQuestion: Identifiable, Equatable, Sendable {
    let id = UUID()
    let host: String
    /// Keep running or End sessions, or closing tabs that stop everything in them; never `closeWithoutAsking`.
    let question: SeveralTabsClosingQuestion
}
