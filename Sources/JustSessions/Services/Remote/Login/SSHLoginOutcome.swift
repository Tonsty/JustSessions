import Foundation

/// How a login made with Connect… ended.
enum SSHLoginOutcome: Equatable, Sendable {
    case loggedIn
    /// Someone cancelled a question; nothing needs saying.
    case cancelled
    case failed(SSHConnectionProblem)
}
