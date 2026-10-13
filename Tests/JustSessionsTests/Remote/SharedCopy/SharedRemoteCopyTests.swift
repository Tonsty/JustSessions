import Foundation
import Testing
@testable import JustSessions

/// Once one window has copied an SSH host, the other windows list that copy instead of copying the host again.
@MainActor
struct SharedRemoteCopyTests {
    @Test func anotherWindowListsTheCopy() async throws {
        let sandbox = try TwoWindowSandbox()
        defer { sandbox.tearDown() }
        let (discovery, sessionID) = try Self.copyWithOneClaudeSession(in: sandbox)
        let refreshedAt = Date.now
        let status = RemoteHostStatus(tmuxSessionNames: ["justsessions-claude-1"], installedProviders: [.claude])

        sandbox.first.shareRemoteHostCopy("devbox", refreshedAt: refreshedAt, status: status, discovery: discovery)

        try await expectEventually { sandbox.second.hostRefreshStatuses[.ssh("devbox")] == .refreshed(refreshedAt) }
        #expect(sandbox.second.conversations.filter { $0.host == .ssh("devbox") }.map(\.sessionID) == [sessionID])
        #expect(sandbox.second.tmuxSessionNamesByHost[.ssh("devbox")] == ["justsessions-claude-1"])
        #expect(sandbox.first.hostRefreshStatuses[.ssh("devbox")] == nil)
    }

    /// Its own refresh lists the host when it ends.
    @Test func aWindowRefreshingTheHostItselfIsLeftToItsRefresh() async throws {
        let sandbox = try TwoWindowSandbox()
        defer { sandbox.tearDown() }
        let (discovery, _) = try Self.copyWithOneClaudeSession(in: sandbox)
        sandbox.second.hostRefreshStatuses[.ssh("devbox")] = .refreshing

        sandbox.first.shareRemoteHostCopy("devbox", refreshedAt: .now, status: nil, discovery: discovery)
        try await Task.sleep(for: .milliseconds(200))

        #expect(sandbox.second.hostRefreshStatuses[.ssh("devbox")] == .refreshing)
        #expect(!sandbox.second.conversations.contains { $0.host == .ssh("devbox") })
    }

    /// Both windows list `devbox`, whose copy holds one Claude Code session.
    private static func copyWithOneClaudeSession(in sandbox: TwoWindowSandbox) throws -> (RemoteSessionDiscovery, String) {
        for store in [sandbox.first, sandbox.second] { store.remoteHostList = RemoteHostList(hosts: ["devbox"]) }
        let mirror = RemoteSessionMirror(cacheRoot: sandbox.root.appendingPathComponent("cache"), sourceHomeOverride: sandbox.root.path)
        let project = mirror.mirrorDirectory(host: "devbox", provider: .claude).appendingPathComponent("projects/-srv-app")
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let sessionID = UUID().uuidString.lowercased()
        try #"{"type":"user","cwd":"/srv/app","message":{"content":"Fix the build"}}"#
            .appending("\n")
            .write(to: project.appendingPathComponent("\(sessionID).jsonl"), atomically: true, encoding: .utf8)
        return (RemoteSessionDiscovery(mirror: mirror), sessionID)
    }
}
