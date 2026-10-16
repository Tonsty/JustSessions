import Testing

/// Runs the tests of the suites it marks one at a time, across all of them: the suites whose synchronous tests wait on a
/// `TmuxSandbox` with `Thread.sleep` and `waitUntilExit()`.
///
/// Such a test holds one of Swift concurrency's shared threads for as long as it runs, and the release runner has only
/// three. With every sandbox suite running at once, the whole test process stalled at the start of a full run: 35
/// seconds in v1.2.12's passing run and 46 in v1.2.13's failing ones, after which every test that started then finished
/// together. Tests that wait on a background task or a stand-in CLI failed behind it. A test waiting here for its turn
/// holds no thread.
struct OneTmuxSandboxAtATime: SuiteTrait, TestTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        await Self.turn.take()
        do {
            try await function()
        } catch {
            await Self.turn.handOn()
            throw error
        }
        await Self.turn.handOn()
    }

    private static let turn = TmuxSandboxTurn()
}

extension SuiteTrait where Self == OneTmuxSandboxAtATime {
    static var oneTmuxSandboxAtATime: Self { Self() }
}

private actor TmuxSandboxTurn {
    private var isTaken = false
    private var waitingTests: [CheckedContinuation<Void, Never>] = []

    func take() async {
        guard isTaken else {
            isTaken = true
            return
        }
        await withCheckedContinuation { continuation in
            waitingTests.append(continuation)
        }
    }

    /// To the test that has waited longest, if one waits.
    func handOn() {
        if waitingTests.isEmpty {
            isTaken = false
        } else {
            waitingTests.removeFirst().resume()
        }
    }
}
