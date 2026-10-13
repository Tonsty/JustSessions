import Foundation

/// What the findings of one host check are read against, besides the host's answers.
struct RemoteHostCheckContext: Sendable {
    let host: String
    /// How the app's commands start the host's login shell, as the shell startup check just found.
    let shellStartup: RemoteShellStartup
    let programs: [RemoteHostCheckProgram]
    /// The session of the ended tab the check started from, if it did.
    let session: HostCheckSession?
    /// Tools with sessions listed under the host, whose CLI a resume needs.
    let providersWithSessions: Set<ConversationProvider>
}
