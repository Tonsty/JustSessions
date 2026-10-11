import Darwin
import Foundation
import Testing
@testable import JustSessions

/// The askpass helper hands `ssh`'s question to the running app over the login's socket, and prints the answer.
struct SSHAskpassRelayTests {
    @Test func theAppStartsAsItselfWithoutTheLoginsSocket() {
        #expect(SSHAskpassRelay.exitStatusIfStartedAsAskpass(arguments: ["JustSessions"], environment: [:]) == nil)
    }

    @Test func theHelperGetsTheAnswerTypedInTheApp() async throws {
        let folder = makeShortSocketFolder()
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let asked = LockedValue<[SSHAskpassRequest]>([])
        let server = try #require(SSHAskpassServer(socketPath: folder + "/askpass") { request in
            asked.update { $0.append(request) }
            return SSHAskpassReply(answer: "hunter2")
        })
        defer { server.stop() }

        let request = SSHAskpassRequest(prompt: "(me@devbox) Password:", hint: nil)
        let answer = await Task.detached { SSHAskpassRelay.answer(to: request, socketPath: server.socketPath) }.value

        #expect(answer == "hunter2")
        #expect(asked.value == [request])
    }

    @Test func aCancelledQuestionFailsTheHelper() async throws {
        let folder = makeShortSocketFolder()
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let server = try #require(SSHAskpassServer(socketPath: folder + "/askpass") { _ in SSHAskpassReply(answer: nil) })
        defer { server.stop() }

        let request = SSHAskpassRequest(prompt: "Verification code:", hint: nil)
        let answer = await Task.detached { SSHAskpassRelay.answer(to: request, socketPath: server.socketPath) }.value

        #expect(answer == nil)
    }

    /// `ssh` ends the helper of a notice, such as to touch a security key, once it is done with it.
    @Test func aHelperThatGoesAwayWithdrawsItsQuestion() async throws {
        let folder = makeShortSocketFolder()
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let wasWithdrawn = LockedValue(false)
        let server = try #require(SSHAskpassServer(socketPath: folder + "/askpass") { _ in
            try? await Task.sleep(for: .seconds(60))
            wasWithdrawn.update { $0 = Task.isCancelled }
            return SSHAskpassReply(answer: nil)
        })
        defer { server.stop() }

        let helper = try UnixStreamSocket(connectingTo: server.socketPath, timeout: .seconds(5))
        try helper.write(try #require(SSHAskpassMessageLine.encoded(
            SSHAskpassRequest(prompt: "Confirm user presence for key ED25519-SK", hint: "none")
        )))
        try await Task.sleep(for: .milliseconds(100))
        helper.close()

        try await expectEventually { wasWithdrawn.value }
    }

    @Test func stoppingTheServerCancelsTheQuestionsWaiting() async throws {
        let folder = makeShortSocketFolder()
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(atPath: folder) }
        let isAsking = LockedValue(false)
        let server = try #require(SSHAskpassServer(socketPath: folder + "/askpass") { _ in
            isAsking.update { $0 = true }
            try? await Task.sleep(for: .seconds(60))
            return SSHAskpassReply(answer: Task.isCancelled ? nil : "late")
        })

        let request = SSHAskpassRequest(prompt: "(me@devbox) Password:", hint: nil)
        let answer = Task.detached { SSHAskpassRelay.answer(to: request, socketPath: server.socketPath) }
        try await expectEventually { isAsking.value }
        server.stop()

        #expect(await answer.value == nil)
        #expect(!FileManager.default.fileExists(atPath: server.socketPath))
    }
}
