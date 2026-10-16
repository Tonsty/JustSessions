import Foundation
import Testing
@testable import JustSessions

/// Runs the remote tab's command against a real tmux on this Mac, with a private tmux server and home folder,
/// and stand-ins for the host's login shell and CLI. Skipped where tmux is not installed.
@Suite(.oneTmuxSandboxAtATime)
struct RemoteTmuxKeepAliveTests {
    @Test func cliKeepsRunningAfterDisconnectAndReopeningReattaches() throws {
        guard let tmuxPath = ["/opt/homebrew/bin/tmux", "/usr/local/bin/tmux", "/usr/bin/tmux"]
            .first(where: FileManager.default.isExecutableFile(atPath:)) else { return }
        let sandbox = try TmuxSandbox(tmuxDirectory: URL(fileURLWithPath: tmuxPath).deletingLastPathComponent().path)
        defer { sandbox.tearDown() }
        let tmuxName = TmuxSessionName.unique(for: .claude)
        let command = RemoteCLICommandBuilder.remoteCommand(
            provider: .claude,
            projectPath: sandbox.project.path,
            arguments: ["--resume", "abc"],
            tmuxSessionName: tmuxName
        )

        let firstClient = try sandbox.startClient(command)
        #expect(sandbox.waitUntil { sandbox.launchCount == 1 })
        #expect(sandbox.launchRecord?.hasSuffix("/Bob's paper\n--resume\nabc\n") == true)
        #expect(sandbox.hasTmuxSession(tmuxName))
        let options = sandbox.run("tmux show-options -t \(ShellQuoting.quoted(tmuxName))")
        #expect(options.contains("status off"))
        // The title reaches the tab, where Claude Code's relay says what the CLI does; see `RemoteClaudeActivityRelay`.
        #expect(options.contains("set-titles on"))
        #expect(options.contains("set-titles-string \"\(RemoteCLIActivityTitle.titleFormat)\""))
        #expect(options.contains("mouse on"))
        #expect(options.contains("prefix None"))
        #expect(options.contains("prefix2 None"))
        let windowOptions = sandbox.run("tmux show-options -w -t \(ShellQuoting.quoted(tmuxName))")
        #expect(windowOptions.contains("allow-passthrough on"))

        // The connection drops: the client goes away, the CLI stays.
        firstClient.terminate()
        firstClient.waitUntilExit()
        #expect(sandbox.hasTmuxSession(tmuxName))
        #expect(RemoteHostStatusProbe.status(inOutput: sandbox.run(RemoteHostStatusProbe.command(on: "devbox"))).tmuxSessionNames == [tmuxName])

        // Opening it again attaches instead of starting the CLI a second time. The server waits after Esc as tmux
        // before 3.5 does, until the attach sets it to 10 ms.
        _ = sandbox.run("tmux set-option -s escape-time 500")
        let secondClient = try sandbox.startClient(command)
        Thread.sleep(forTimeInterval: 1.5)
        #expect(sandbox.launchCount == 1)
        #expect(sandbox.run("tmux show-options -s escape-time").contains("escape-time 10"))
        secondClient.terminate()
        secondClient.waitUntilExit()

        let renamed = tmuxName + "-renamed"
        _ = sandbox.run(RemoteTmuxCommands.renameSessionCommand(from: tmuxName, to: renamed, on: "devbox"))
        #expect(sandbox.hasTmuxSession(renamed))
        _ = sandbox.run(RemoteTmuxCommands.killSessionCommand(renamed, on: "devbox"))
        #expect(sandbox.waitUntil { !sandbox.hasTmuxSession(renamed) })
    }

    @Test func hostWithoutTmuxRunsTheCLIDirectly() throws {
        let sandbox = try TmuxSandbox(tmuxDirectory: nil)
        defer { sandbox.tearDown() }
        try sandbox.makeCLIExitAtOnce()
        let command = RemoteCLICommandBuilder.remoteCommand(
            provider: .claude,
            projectPath: sandbox.project.path,
            arguments: ["--resume", "abc"],
            tmuxSessionName: TmuxSessionName.unique(for: .claude)
        )
        _ = sandbox.run(command)
        #expect(sandbox.launchRecord?.hasSuffix("/Bob's paper\n--resume\nabc\n") == true)
    }
}
