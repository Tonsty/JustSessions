import Testing

/// Runs the tests it marks one at a time, across every suite and test it marks: tests whose stand-in holds one of Swift
/// concurrency's shared threads until the test lets it go, such as a deletion held at its SSH attempt, a host check held
/// at its login, or a discovery held until the test lets it finish.
///
/// The test lets it go from its own task, and waking that task takes a free shared thread. With several of these tests
/// at once, their stand-ins could hold every shared thread, and then none of the tests could wake to let theirs go. The
/// release runner has three: v1.2.11's first release run and v1.2.14's second hung that way, about 2,000 tests started
/// and none finished for over 40 minutes. One at a time, at most one thread is held this way and the others stay free
/// to wake it. A test waiting here for its turn holds no thread. See `OneTmuxSandboxAtATime` for the other kind of test
/// that holds a thread while it runs.
struct OneHeldThreadAtATime: SuiteTrait, TestTrait, TestScoping {
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

extension SuiteTrait where Self == OneHeldThreadAtATime {
    static var oneHeldThreadAtATime: Self { Self() }
}

extension TestTrait where Self == OneHeldThreadAtATime {
    static var oneHeldThreadAtATime: Self { Self() }
}
