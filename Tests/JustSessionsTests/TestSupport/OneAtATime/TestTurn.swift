/// Lets one test run at a time, in the order they asked; see `OneTmuxSandboxAtATime` and `OneHeldThreadAtATime`. A test
/// waiting for its turn is suspended, so it holds none of Swift concurrency's shared threads.
actor TestTurn {
    private var isTaken = false
    private var waitingTests: [CheckedContinuation<Void, Never>] = []

    /// Runs `test` once it's its turn, outside this actor, as the trait that scopes it would have run it.
    nonisolated func run(_ test: @Sendable () async throws -> Void) async throws {
        await take()
        do {
            try await test()
        } catch {
            await handOn()
            throw error
        }
        await handOn()
    }

    private func take() async {
        guard isTaken else {
            isTaken = true
            return
        }
        await withCheckedContinuation { continuation in
            waitingTests.append(continuation)
        }
    }

    /// To the test that has waited longest, if one waits.
    private func handOn() {
        if waitingTests.isEmpty {
            isTaken = false
        } else {
            waitingTests.removeFirst().resume()
        }
    }
}
