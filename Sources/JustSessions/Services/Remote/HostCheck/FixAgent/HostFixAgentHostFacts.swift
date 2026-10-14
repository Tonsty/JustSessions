import Foundation

/// How JustSessions uses the checked host, for the agent that fixes what the check found, with the host's own values:
/// the agent can't see the app, and would otherwise guess.
struct HostFixAgentHostFacts: Equatable, Sendable {
    let host: String
    let shellStartup: RemoteShellStartup
    let usesHostTmuxPrefix: Bool
    /// JustSessions' tmux sessions on the host, as its last refresh listed them; nil when it couldn't list them.
    let runningTmuxSessionNames: Set<String>?
    /// What the last refresh's tmux printed when it couldn't reach the server; see `RemoteHostStatus`.
    let tmuxServerProblem: String?
    /// The session the check came from, whose tab command the facts show; nil shows Claude Code's in a made-up folder.
    let session: HostCheckSession?

    var lines: [String] {
        let exampleProvider = session?.provider ?? .claude
        let exampleFolder = session?.projectPath ?? "/path/to/project"
        let tabCommand = RemoteCLICommandBuilder.remoteCommand(
            provider: exampleProvider,
            projectPath: exampleFolder,
            arguments: [],
            tmuxSessionName: TmuxSessionName.forSession(provider: exampleProvider, sessionID: "<session id>"),
            usesHostTmuxPrefix: usesHostTmuxPrefix,
            shellStartup: shellStartup
        )
        var lines = [
            "- Every command JustSessions runs on \(host), a tab's too, starts in the user's login shell with "
                + "\(RemoteShellStartup.environmentVariable)=1 set, as `\(shellStartup.command(running: "<command>"))`."
                + (shellStartup == .loginOnly
                    ? " It leaves out `-i` on this host, because its interactive startup files keep a CLI from starting."
                    : ""),
            "- A session's tab runs `ssh -t \(host) '<command>'`, with `-o RemoteCommand=none` and keep-alive options. "
                + "For \(exampleProvider.rawValue) in \(exampleFolder), the command is:",
            "",
            "    \(tabCommand)",
            "",
            "- Sessions run in the host's default tmux server, the one a plain `tmux` reaches, which the user's own tmux "
                + "sessions share. JustSessions names its sessions `\(TmuxSessionName.prefix)<cli>-<session id>`. "
                + (usesHostTmuxPrefix
                    ? "They use the prefix key from the host's ~/.tmux.conf."
                    : "They have no prefix key, so every key reaches the CLI."),
            "- " + runningTmuxSessionsLine,
            "- Each refresh copies the CLIs' session files from the host with rsync over ssh, and in one login shell lists "
                + "the tmux sessions and the CLIs installed.",
        ]
        if let session {
            lines.append("- The check came from a tab of \(session.provider?.rawValue ?? "a terminal") in \(session.projectPath).")
        }
        return lines
    }

    private var runningTmuxSessionsLine: String {
        if let tmuxServerProblem {
            return "The last refresh couldn't reach the tmux server; tmux printed: \(tmuxServerProblem)"
        }
        guard let runningTmuxSessionNames else { return "The last refresh couldn't list the tmux sessions." }
        guard !runningTmuxSessionNames.isEmpty else { return "The last refresh found no JustSessions tmux session running." }
        return "The last refresh found these JustSessions tmux sessions running: "
            + runningTmuxSessionNames.sorted().joined(separator: ", ") + "."
    }
}
