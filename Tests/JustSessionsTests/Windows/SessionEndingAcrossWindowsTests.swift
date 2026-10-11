import Foundation
import Testing
@testable import JustSessions

/// End session, from a session's row, stops its CLI wherever it runs: in a tab of either window, or in tmux with no
/// tab open.
@MainActor
struct SessionEndingAcrossWindowsTests {
    @Test func endingASessionClosesItsTabInAnotherWindow() throws {
        let sandbox = try TwoWindowSandbox()
        defer { sandbox.tearDown() }
        _ = try #require(sandbox.openTab(of: sandbox.conversation, in: sandbox.first))
        #expect(sandbox.second.canEndSession(sandbox.conversation))

        sandbox.second.endSession(sandbox.conversation)

        #expect(sandbox.first.terminalSessions.isEmpty)
        #expect(!sandbox.first.canEndSession(sandbox.conversation))
        #expect(!sandbox.second.canEndSession(sandbox.conversation))
    }

    /// Both windows list the tmux session, and neither does once it has ended.
    @Test func endingASessionRunningInTmuxWithoutATabForgetsItInEveryWindow() throws {
        let sandbox = try TwoWindowSandbox()
        defer { sandbox.tearDown() }
        let tmuxSessionName = TmuxSessionName.forConversation(sandbox.conversation)
        for store in [sandbox.first, sandbox.second] { store.setTmuxSessionNames([tmuxSessionName], on: .thisMac) }
        #expect(sandbox.second.canEndSession(sandbox.conversation))

        sandbox.second.endSession(sandbox.conversation)

        #expect(!sandbox.first.isRunningInTmux(sandbox.conversation))
        #expect(!sandbox.second.isRunningInTmux(sandbox.conversation))
    }

    @Test func aSessionNothingRunsCannotBeEnded() throws {
        let sandbox = try TwoWindowSandbox()
        defer { sandbox.tearDown() }
        let endedTab = try #require(sandbox.openTab(of: sandbox.conversation, in: sandbox.first))
        endedTab.processFinished(exitCode: 0)

        #expect(!sandbox.first.canEndSession(sandbox.conversation))
        #expect(!sandbox.second.canEndSession(sandbox.conversation))
    }
}
