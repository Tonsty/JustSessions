import Foundation
import Testing
@testable import JustSessions

/// The session runs a local `sh` script in place of `ssh`: it reads its answers from a pipe, as the command on the
/// host reads them from its terminal, and `echo` stands in for a terminal echoing what's typed.
struct RemoteSignInSessionTests {
    private static let fastTiming = RemoteSignInSession.Timing(
        promptPause: .milliseconds(100),
        linePause: .milliseconds(300),
        pollInterval: .milliseconds(20),
        timeLimit: .seconds(20)
    )

    private func session(running script: String, timing: RemoteSignInSession.Timing = fastTiming) -> RemoteSignInSession {
        RemoteSignInSession(
            host: "devbox",
            command: "sign-in",
            launcher: RemoteSignInSession.Launcher { _, _ in
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/sh")
                process.arguments = ["-c", script]
                return process
            },
            timing: timing
        )
    }

    /// Records each question and answers from `answers` by prompt.
    private final class Asker: @unchecked Sendable {
        private let lock = NSLock()
        private let answers: [String: String]
        private(set) var questions: [SSHAskpassQuestion] = []

        init(_ answers: [String: String]) { self.answers = answers }

        var asked: [SSHAskpassQuestion] { lock.withLock { questions } }

        func ask(_ question: SSHAskpassQuestion) async -> String? {
            lock.withLock { questions.append(question) }
            guard let answer = answers[question.prompt] else {
                // Waits to be taken back, as a question shown in the dialog does.
                while !Task.isCancelled { try? await Task.sleep(for: .milliseconds(10)) }
                return nil
            }
            return answer
        }
    }

    private static let pinThenCode = """
        printf 'Signing in as me\\nPIN: '
        read pin
        echo "$pin"
        printf 'One-time code: '
        read code
        echo "$code"
        [ "$pin" = 1234 ] && [ "$code" = 987654 ]
        """

    @Test func asksEachQuestionInTurnAndSignsIn() async {
        let asker = Asker(["PIN:": "1234", "One-time code:": "987654"])

        let outcome = await session(running: Self.pinThenCode).run(ask: asker.ask)

        #expect(outcome == .signedIn)
        #expect(asker.asked.map(\.prompt) == ["PIN:", "One-time code:"])
        #expect(asker.asked.map(\.context) == ["Signing in as me", nil])
        #expect(asker.asked.allSatisfy { $0.asker == .signInCommand && $0.kind == .secret && $0.host == "devbox" })
    }

    @Test func aQuestionAskedAgainSaysTheAnswerWasntAccepted() async {
        let script = """
            printf 'PIN: '
            read pin
            while [ "$pin" != 1234 ]; do
              printf '\\nWrong PIN.\\nPIN: '
              read pin
            done
            """
        final class Answers: @unchecked Sendable {
            private let lock = NSLock()
            private var remaining = ["0000", "1234"]
            private(set) var asked: [SSHAskpassQuestion] = []
            func ask(_ question: SSHAskpassQuestion) async -> String? {
                lock.withLock {
                    asked.append(question)
                    return remaining.removeFirst()
                }
            }
        }
        let answers = Answers()

        let outcome = await session(running: script).run(ask: answers.ask)

        #expect(outcome == .signedIn)
        #expect(answers.asked.map(\.isAskedAgain) == [false, true])
        #expect(answers.asked.last?.context == "Wrong PIN.")
    }

    @Test func aPromptOnALineOfItsOwnIsAskedOnceTheCommandWaits() async {
        let asker = Asker(["Press your key to type its code": "cccccvbfhrnk"])

        let outcome = await session(running: "echo 'Press your key to type its code'; read code; [ \"$code\" = cccccvbfhrnk ]")
            .run(ask: asker.ask)

        #expect(outcome == .signedIn)
        #expect(asker.asked.map(\.prompt) == ["Press your key to type its code"])
    }

    @Test func aPauseWhileTheCommandStillWorksTakesItsQuestionBack() async {
        let asker = Asker(["PIN:": "1234"])

        let outcome = await session(running: "echo 'Contacting the server'; sleep 1; printf 'PIN: '; read pin; [ \"$pin\" = 1234 ]")
            .run(ask: asker.ask)

        #expect(outcome == .signedIn)
        #expect(asker.asked.map(\.prompt) == ["Contacting the server", "PIN:"])
        #expect(asker.asked.last?.context == "Contacting the server")
    }

    @Test func cancellingAQuestionStopsTheCommand() async {
        let started = ContinuousClock.now

        let outcome = await session(running: "printf 'PIN: '; read pin; sleep 30").run { _ in nil }

        #expect(outcome == .cancelled)
        #expect(ContinuousClock.now - started < .seconds(10))
    }

    @Test func aFailureSaysWhatTheCommandPrinted() async {
        let outcome = await session(running: "echo 'Your account is locked'; exit 3").run { _ in nil }

        guard case .failed(let message) = outcome else {
            Issue.record("Expected a failure, got \(outcome)")
            return
        }
        #expect(message.contains("exit status 3"))
        #expect(message.contains("Your account is locked"))
    }

    @Test func aCommandThatNeverEndsIsStoppedAtTheTimeLimit() async {
        var timing = Self.fastTiming
        timing.timeLimit = .seconds(1)

        let outcome = await session(running: "sleep 30", timing: timing).run { _ in nil }

        guard case .failed = outcome else {
            Issue.record("Expected a failure, got \(outcome)")
            return
        }
    }
}
