import Foundation
import Testing
@testable import JustSessions

/// What the app sends an SSH host's tmux, by the version `tmux -V` names, through a stand-in tmux that records it. Each
/// version's answers were tried against real tmux 1.8 to 3.6a; see `RemoteTmuxGeneration`.
struct RemoteTmuxOlderVersionsTests {
    private static let sessionName = "justsessions-claude-new-1a2b3c4d"

    /// Older tmux has no `mouse`, no `None` key, or fails on `allow-passthrough`; one failing option would show an
    /// error in the tab and skip the options after it. Before 2.4, `xterm-keys` is off unless turned on.
    @Test(arguments: [
        ("tmux 1.8", "set-option status off ; set-option mode-mouse on ; set-option -w xterm-keys on ; set-option -s escape-time 10 ; set-option prefix C-M-S-IC ; set-option prefix2 C-M-S-IC"),
        ("tmux 2.0", "set-option status off ; set-option mode-mouse on ; set-option -w xterm-keys on ; set-option -s escape-time 10 ; set-option prefix C-M-S-IC ; set-option prefix2 C-M-S-IC"),
        ("tmux 2.1", "set-option status off ; set-option mouse on ; set-option -w xterm-keys on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix C-M-S-IC ; set-option prefix2 C-M-S-IC"),
        ("tmux 2.2", "set-option status off ; set-option mouse on ; set-option -w xterm-keys on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix None ; set-option prefix2 None"),
        ("tmux 2.3", "set-option status off ; set-option mouse on ; set-option -w xterm-keys on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix None ; set-option prefix2 None"),
        ("tmux 2.4", "set-option status off ; set-option mouse on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix None ; set-option prefix2 None"),
        ("tmux 3.1c", "set-option status off ; set-option mouse on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix None ; set-option prefix2 None"),
        ("tmux 3.4", "set-option status off ; set-option mouse on ; set-option -wq allow-passthrough on ; set-option -s escape-time 10 ; set-option prefix None ; set-option prefix2 None ; set-option -w remain-on-exit failed ; set-hook pane-died"),
    ])
    func eachVersionGetsOnlyOptionsItUnderstands(version: String, options: String) throws {
        let sandbox = try stubbedTmux(version: version)
        defer { sandbox.tearDown() }

        _ = sandbox.run(tabCommand(usingHostPrefix: false))

        let newSession = try #require(recordedCalls(in: sandbox).first { $0.hasPrefix("new-session ") })
        let firstOption = try #require(newSession.range(of: "set-option status off"))
        let attachOptions = String(newSession[firstOption.lowerBound...])
        #expect(attachOptions.hasPrefix(options))
        if !version.hasPrefix("tmux 3.4") { #expect(!attachOptions.contains("remain-on-exit")) }
    }

    @Test(arguments: ["tmux 1.8", "tmux 2.1", "tmux 3.4"])
    func theHostsOwnPrefixIsTheSameForEveryVersion(version: String) throws {
        let sandbox = try stubbedTmux(version: version)
        defer { sandbox.tearDown() }

        _ = sandbox.run(tabCommand(usingHostPrefix: true))
        _ = sandbox.run(RemoteTmuxCommands.setPrefixOptionsCommand(usingHostPrefix: true, on: "devbox"))

        let calls = recordedCalls(in: sandbox)
        #expect(calls.contains { $0.hasPrefix("new-session ") && $0.contains("set-option -u prefix ; set-option -u prefix2") })
        #expect(calls.contains { $0.contains("-u prefix ; set-option -t") && $0.hasSuffix("-u prefix2") })
    }

    /// tmux before 2.1 takes `=` as part of a session's name, so it would find no session and leave a deleted
    /// session's CLI running; there a plain name, which tmux matches exactly first, names the session.
    @Test(arguments: [("tmux 1.8", ""), ("tmux 2.0", ""), ("tmux 2.1", "="), ("tmux 3.4", "=")])
    func everyCommandTargetsExactlyItsSession(version: String, exactPrefix: String) throws {
        let sandbox = try stubbedTmux(version: version)
        defer { sandbox.tearDown() }

        _ = sandbox.run(tabCommand(usingHostPrefix: false))
        _ = sandbox.run(RemoteTmuxCommands.hasSessionCommand(Self.sessionName, on: "devbox"))
        _ = sandbox.run(RemoteTmuxCommands.killSessionWaitingForCLIExitCommand(Self.sessionName, on: "devbox", timeoutSeconds: 1))
        _ = sandbox.run(RemoteTmuxCommands.setPrefixOptionsCommand(usingHostPrefix: false, on: "devbox"))

        let calls = recordedCalls(in: sandbox)
        let targets = calls.flatMap { call -> [String] in
            let words = call.split(separator: " ").map(String.init)
            // The `pane-died` hook quotes its commands.
            return zip(words, words.dropFirst()).filter { $0.0 == "-t" }.map { $0.1.trimmingCharacters(in: ["'", "\""]) }
        }
        for command in ["display-message", "kill-session", "has-session", "set-option -t"] {
            #expect(calls.contains { $0.hasPrefix(command) }, "\(command) was not sent")
        }
        #expect(!targets.isEmpty)
        #expect(Set(targets).isSubset(of: [exactPrefix + Self.sessionName, exactPrefix + Self.sessionName + ":"]), "\(targets)")
        let unusedKey = version == "tmux 3.4" ? "None" : "C-M-S-IC"
        #expect(calls.contains { $0.hasPrefix("set-option -t") && $0.hasSuffix("prefix2 \(unusedKey)") })
    }

    /// A tmux that answers `-V` as `version`, writes each call's arguments on a line of `calls`, and lists one
    /// JustSessions session. Its `display-message` says the pane is dead, so the tab's command ends it, and gives no
    /// pane process, so ending a session waits for none.
    private func stubbedTmux(version: String) throws -> TmuxSandbox {
        let sandbox = try TmuxSandbox(tmuxDirectory: nil)
        try sandbox.addProgram(named: "tmux", script: """
            [ "$1" = -V ] && { echo '\(version)'; exit 0; }
            echo "$*" >> "$HOME/calls"
            case $1 in
            list-sessions) echo '\(Self.sessionName)' ;;
            display-message) case "$*" in *'#{pane_dead}'*) echo 1 ;; esac ;;
            esac
            exit 0
            """)
        return sandbox
    }

    private func tabCommand(usingHostPrefix: Bool) -> String {
        RemoteCLICommandBuilder.remoteCommand(
            provider: .claude,
            projectPath: "/tmp",
            arguments: [],
            tmuxSessionName: Self.sessionName,
            usesHostTmuxPrefix: usingHostPrefix
        )
    }

    private func recordedCalls(in sandbox: TmuxSandbox) -> [String] {
        let calls = (try? String(contentsOf: sandbox.root.appendingPathComponent("calls"), encoding: .utf8)) ?? ""
        return calls.split(separator: "\n").map(String.init)
    }
}
