import Foundation

/// What a remote host runs, as of its last refresh.
struct RemoteHostStatus: Equatable, Sendable {
    /// The tmux sessions JustSessions started there that still run.
    let tmuxSessionNames: Set<String>
    /// Where each tool's CLI the host has is; nil when the output did not say.
    let cliLocations: [ConversationProvider: RemoteCLILocation]?
    /// What the host's tmux printed when it couldn't reach the tmux server running there, as after tmux was upgraded
    /// while sessions ran; nil when it reached it, or no server runs. See `RemoteHostTmuxFinding`.
    var tmuxServerProblem: String? = nil

    /// The tools whose CLI the host has; nil when the output did not say.
    var installedProviders: Set<ConversationProvider>? {
        cliLocations.map { Set($0.keys) }
    }
}
