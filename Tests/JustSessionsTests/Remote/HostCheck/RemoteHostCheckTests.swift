import Foundation
import Testing
@testable import JustSessions

/// The check's steps, with `ssh` stood in for: the login, the shell startup, then the script.
struct RemoteHostCheckTests {
    static let shellStartupWorks = "__JUSTSESSIONS_SHELL_STARTUP_OK__\r\n"

    @Test func aHostTheAppCannotLogInToIsAskedNothingMore() {
        let recorder = RemoteCommandRecorder()
        let check = RemoteHostCheck(
            runner: recorder.runner(answering: (0, "")),
            connectionCheck: RemoteHostConnectionCheck(runner: recorder.runner(answering: (
                RemoteHostCommandRunner.connectionFailureExitStatus,
                "me@devbox: Permission denied (publickey)."
            ))),
            shellStartupCheck: RemoteShellStartupCheck(run: { _, _, _ in Issue.record("Checked the shell startup"); return nil })
        )

        let outcome = check.check(host: "devbox", programs: [], session: nil, providersWithSessions: [], thisMacSummary: "This Mac")

        #expect(outcome.report.findings.map(\.id) == ["connection"])
        #expect(outcome.report.findings.first?.status == .problem)
        #expect(outcome.shellStartupResult == nil)
        #expect(recorder.commands.map(\.command) == [WindowsHostProbe.command])
    }

    @Test func runsTheScriptInTheStartupTheShellStartupCheckFound() throws {
        let recorder = RemoteCommandRecorder()
        let scriptOutput = hostCheckScriptOutput([
            "rsync-path": "/usr/bin/rsync",
            "shell": "/bin/bash",
            "tmux-path": "/usr/bin/tmux",
            "tmux-version": "tmux 3.4",
            "tmux-server": "3.4",
            "tmux-server-exit": "0",
            "done": "",
        ])
        let check = RemoteHostCheck(
            runner: recorder.runner(answering: (0, scriptOutput)),
            connectionCheck: RemoteHostConnectionCheck(runner: recorder.runner(answering: (0, "%OS% :OS\n"))),
            shellStartupCheck: RemoteShellStartupCheck(run: { _, command, _ in
                command == RemoteShellStartupCheck.tracedInteractiveCommand
                    ? (nil, "+JUSTSESSIONS /home/me/.bashrc:7: exec tmux\r\n")
                    : (0, Self.shellStartupWorks)
            })
        )

        let outcome = check.check(
            host: "devbox",
            programs: [],
            session: nil,
            providersWithSessions: [],
            thisMacSummary: "JustSessions 1.2.10 · macOS 26.0.1",
            now: { Date(timeIntervalSince1970: 0) }
        )

        #expect(outcome.shellStartupResult?.outcome == .usesLoginShellOnly)
        #expect(outcome.report.findings.map(\.id) == ["connection", "shell-startup", "system", "rsync", "tmux"])
        #expect(outcome.report.findings[1].status == .warning)
        #expect(outcome.report.findings[1].hostOutput == "/home/me/.bashrc:7: exec tmux")
        #expect(outcome.report.thisMacSummary == "JustSessions 1.2.10 · macOS 26.0.1")
        let scriptCommand = try #require(recorder.commands.last?.command)
        #expect(scriptCommand.contains("\"$SHELL\" -lc "))
    }

    @Test func aScriptThatDoesNotFinishIsAProblem() {
        let recorder = RemoteCommandRecorder()
        let check = RemoteHostCheck(
            runner: recorder.runner(answering: nil),
            connectionCheck: RemoteHostConnectionCheck(runner: recorder.runner(answering: (0, "%OS% :OS\n"))),
            shellStartupCheck: RemoteShellStartupCheck(run: { _, _, _ in (0, Self.shellStartupWorks) })
        )

        let outcome = check.check(host: "devbox", programs: [], session: nil, providersWithSessions: [], thisMacSummary: "This Mac")

        #expect(outcome.report.findings.map(\.id) == ["connection", "shell-startup", "script"])
        #expect(outcome.report.findings.map(\.status) == [.passed, .passed, .problem])
        #expect(outcome.shellStartupResult?.outcome == .interactiveStartupWorks)
    }
}
