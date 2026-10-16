import Testing

/// Runs the tests of the suites it marks one at a time, across all of them: the suites whose synchronous tests wait on a
/// `TmuxSandbox` with `Thread.sleep` and `waitUntilExit()`.
///
/// Such a test holds one of Swift concurrency's shared threads for as long as it runs, and the release runner has only
/// three. With every sandbox suite running at once, the whole test process stalled at the start of a full run: 35
/// seconds in v1.2.12's passing run and 46 in v1.2.13's failing ones, after which every test that started then finished
/// together. Tests that wait on a background task or a stand-in CLI failed behind it. A test waiting here for its turn
/// holds no thread. See `OneHeldThreadAtATime` for the other kind of test that holds a thread while it runs.
struct OneTmuxSandboxAtATime: SuiteTrait, TestTrait, TestScoping {
    var isRecursive: Bool { true }

    func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        try await Self.turn.run(function)
    }

    private static let turn = TestTurn()
}

extension SuiteTrait where Self == OneTmuxSandboxAtATime {
    static var oneTmuxSandboxAtATime: Self { Self() }
}
