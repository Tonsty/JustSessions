import Foundation

/// What the host's tmux means for its sessions. The app gives each tmux version the commands it understands, from tmux
/// 1.8 on (see `RemoteTmuxGeneration`), so this tells when that tmux can't run them: one older than 1.8 has no
/// `new-session -A` to start or attach to a session, and a tmux client of another version than the running server
/// can't reach it, as after an upgrade while sessions ran. Both were tried against tmux 1.8 to 3.6a. A server older
/// than 2.4 doesn't know `#{version}` and prints nothing for it, so its version isn't compared.
enum RemoteHostTmuxFinding {
    static let oldestSupportedVersion = (major: 1, minor: 8)

    /// What a tmux client prints when the running server is of a version it can't talk to.
    static let unreachableServerPhrases = [
        "protocol version mismatch",
        "server exited unexpectedly",
        "server version is too old",
    ]
    /// What a tmux client prints when no server runs, which is fine.
    static let noServerPhrases = ["no server running", "error connecting to", "no sessions", "no current session"]

    static func finding(in output: RemoteHostCheckOutput, context: RemoteHostCheckContext) -> HostCheckFinding {
        let host = context.host
        let command = RemoteHostCheckCommands.inLoginShell(host, "tmux -V; tmux ls", startup: context.shellStartup)
        func finding(_ status: HostCheckFinding.Status, _ summary: String, hostOutput: String? = nil) -> HostCheckFinding {
            HostCheckFinding(
                id: "tmux", status: status, title: "tmux", summary: summary,
                hostOutput: hostOutput, commandToRunYourself: command
            )
        }

        guard output.text("tmux-path") != nil else {
            return finding(.note, AppLocalization.string(
                "tmux isn't installed on \(host), so CLIs there run without it: closing a tab or losing the connection ends them."
            ))
        }
        let clientVersion = version(inVersionOutput: output.text("tmux-version"))
        let clientName = clientVersion.map { "tmux \($0)" } ?? "tmux"
        let serverOutput = output.text("tmux-server")
        let lowercasedServerOutput = serverOutput?.lowercased() ?? ""

        if unreachableServerPhrases.contains(where: lowercasedServerOutput.contains) {
            return finding(.problem, AppLocalization.string(
                "\(host)'s tmux server was started by another tmux version than \(clientName), the one JustSessions finds there, as when tmux is upgraded while sessions run. Its sessions keep running but can't be opened. Reattach with the tmux that started the server, or end its sessions with that tmux and start them again."
            ), hostOutput: serverOutput)
        }
        if let clientVersion, isOlderThanSupported(clientVersion) {
            return finding(.problem, AppLocalization.string(
                "\(host) has tmux \(clientVersion). JustSessions needs tmux 1.8 or later to open sessions in it."
            ), hostOutput: output.text("tmux-version"))
        }
        let serverRuns = output.exitStatus("tmux-server-exit") == 0
        if serverRuns, let serverVersion = serverOutput, let clientVersion, serverVersion != clientVersion {
            return finding(.warning, AppLocalization.string(
                "\(host)'s tmux server runs tmux \(serverVersion), but the tmux JustSessions finds is \(clientName). Opening a session in that server can fail until its sessions end and the server starts again."
            ), hostOutput: output.text("tmux-version"))
        }
        if !serverRuns, !lowercasedServerOutput.isEmpty, !noServerPhrases.contains(where: lowercasedServerOutput.contains) {
            return finding(.warning, AppLocalization.string("tmux on \(host) answered with an error."), hostOutput: serverOutput)
        }
        return finding(.passed, AppLocalization.string(
            "CLIs run in \(clientName) on \(host), so they keep running when a tab closes or the connection drops."
        ), hostOutput: output.text("tmux-version"))
    }

    /// The line of `output` in which a tmux client says it can't reach the running server, as a refresh's
    /// `tmux list-sessions` prints it; nil when there is none. See `RemoteHostStatusProbe`.
    static func unreachableServerMessage(in output: String) -> String? {
        output.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .first { line in unreachableServerPhrases.contains(where: line.lowercased().contains) }
    }

    /// "3.4" from "tmux 3.4", or "next-3.7" from a build from source.
    static func version(inVersionOutput output: String?) -> String? {
        guard let line = output?.split(separator: "\n").first, line.hasPrefix("tmux ") else { return nil }
        return String(line.dropFirst("tmux ".count)).trimmingCharacters(in: .whitespaces)
    }

    static func isOlderThanSupported(_ version: String) -> Bool {
        guard let match = version.firstMatch(of: #/(\d+)\.(\d+)/#),
              let major = Int(match.1), let minor = Int(match.2) else { return false }
        return (major, minor) < oldestSupportedVersion
    }
}
