import Foundation
import Testing
@testable import JustSessions

/// What a CLI on an SSH host does while no tab shows its tmux session, as the app reads it from the host; see
/// `RemoteTmuxPanes` and `RemoteDetachedActivityReader`.
@MainActor
struct RemoteDetachedActivityTests {
    private static let claudeID = "11111111-2222-4333-8444-555555555555"
    private static let codexID = "01a10846-4c77-75e2-bec8-ab638c1d2e3f"
    private static let claudeName = "justsessions-claude-\(claudeID)"
    private static let codexName = "justsessions-codex-\(codexID)"

    private static func line(_ name: String, _ option: String, _ title: String) -> String {
        [name, option, title].joined(separator: RemoteTmuxPanes.separator)
    }

    // MARK: Reading a listing

    @Test func readsEachSessionsPaneAndLeavesOutWhatIsNotTheApps() throws {
        let output = [
            "Welcome to devbox",
            Self.line(Self.claudeName, "waiting:permission prompt", "✳ Fix login"),
            Self.line(Self.codexName, "", "[ ! ] Action Required | 01a10846-4c77-75e2-bec8-ab638..."),
            Self.line("mine", "", "vim"),
            RemoteTmuxPanes.endMarker,
        ].joined(separator: "\n")

        let panes = try #require(RemoteTmuxPanes.panes(inOutput: output))

        #expect(panes.panesBySessionName.keys.sorted() == [Self.claudeName, Self.codexName])
        #expect(panes.activity(of: .claude, inSession: Self.claudeName) == .needsInput(reason: "permission prompt"))
        #expect(panes.activity(of: .codex, inSession: Self.codexName) == .needsInput(reason: nil))
        #expect(panes.activity(of: .claude, inSession: "justsessions-claude-gone") == nil)
    }

    @Test func readsEachCLIAsItsTabWould() throws {
        func activity(_ provider: ConversationProvider, option: String, title: String) throws -> CLIActivity? {
            let name = "justsessions-\(provider.executableName)-x"
            let panes = try #require(RemoteTmuxPanes.panes(inOutput: "\(Self.line(name, option, title))\n\(RemoteTmuxPanes.endMarker)"))
            return panes.activity(of: provider, inSession: name)
        }

        #expect(try activity(.claude, option: "busy:", title: "✳ Claude Code") == .working)
        #expect(try activity(.claude, option: "", title: "✳ Claude Code") == nil)
        #expect(try activity(.pi, option: "idle:", title: "π") == .idle)
        #expect(try activity(.opencode, option: "waiting:Allow rm -rf build?", title: "OpenCode") == .needsInput(reason: "Allow rm -rf build?"))
        #expect(try activity(.codex, option: "", title: "⠧ Working | 01a10846-4c77-75e2-bec8-ab638...") == .working)
        #expect(try activity(.codex, option: "", title: "Ready | 01a10846-4c77-75e2-bec8-ab638... ⠸") == .idle)
        #expect(try activity(.kiro, option: "busy:", title: "Kiro") == nil)
    }

    /// No server is no session; a cut-off answer, or a server that tmux can't reach, says nothing about them.
    @Test func onlyAFinishedListingFromAReachableServerCounts() {
        #expect(RemoteTmuxPanes.panes(inOutput: "no server running on /tmp/tmux-1000/default\n\(RemoteTmuxPanes.endMarker)")?.panesBySessionName == [:])
        #expect(RemoteTmuxPanes.panes(inOutput: RemoteTmuxPanes.endMarker)?.panesBySessionName == [:])
        #expect(RemoteTmuxPanes.panes(inOutput: Self.line(Self.claudeName, "busy:", "title")) == nil)
        #expect(RemoteTmuxPanes.panes(inOutput: "protocol version mismatch (client 8, server 7)\n\(RemoteTmuxPanes.endMarker)") == nil)
    }

    /// The command against a real tmux on this Mac, through a stand-in login shell.
    @Test func theCommandListsTheAppsSessionsWithWhatTheirCLIsSay() throws {
        guard let tmuxDirectory = TmuxSandbox.installedTmuxDirectory else { return }
        let sandbox = try TmuxSandbox(tmuxDirectory: tmuxDirectory)
        defer { sandbox.tearDown() }
        #expect(RemoteTmuxPanes.panes(inOutput: sandbox.run(RemoteTmuxPanes.command(on: "devbox")))?.panesBySessionName == [:])

        _ = sandbox.run("tmux new-session -d -s \(Self.claudeName) 'sleep 600' \\; set-option -w \(RemoteCLIActivityTitle.optionName) 'waiting:permission prompt'")
        _ = sandbox.run("tmux new-session -d -s \(Self.codexName) 'sleep 600' \\; select-pane -T 'Ready | 01a10846-4c77-75e2-bec8-ab638...'")
        _ = sandbox.run("tmux new-session -d -s mine 'sleep 600'")

        let panes = try #require(RemoteTmuxPanes.panes(inOutput: sandbox.run(RemoteTmuxPanes.command(on: "devbox"))))
        #expect(panes.panesBySessionName.keys.sorted() == [Self.claudeName, Self.codexName])
        #expect(panes.activity(of: .claude, inSession: Self.claudeName) == .needsInput(reason: "permission prompt"))
        #expect(panes.activity(of: .codex, inSession: Self.codexName) == .idle)
    }

    // MARK: Asking hosts

    @Test func asksAHostAtMostEveryFewSecondsAndLaterAfterItFails() async {
        let calls = CallCounter()
        var now = Date(timeIntervalSince1970: 1_000)
        var answers: [RemoteTmuxPanes?] = [RemoteTmuxPanes(panesBySessionName: [:]), nil, RemoteTmuxPanes(panesBySessionName: [:])]
        let answer = AnswerQueue(answers.removeFirst())
        let reader = RemoteDetachedActivityReader(listPanes: { _ in calls.increment(); return answer.next() }, currentDate: { now })

        await reader.ask("devbox")
        #expect(reader.listing(of: "devbox")?.askedAt == now)
        reader.askIfDue("devbox")
        #expect(calls.count == 1)

        now += RemoteDetachedActivityReader.interval
        answer.set(answers.removeFirst())
        await reader.ask("devbox")
        #expect(calls.count == 2)
        // A failure keeps the last listing while it is new enough, and waits before asking again.
        now += RemoteDetachedActivityReader.interval
        reader.askIfDue("devbox")
        #expect(calls.count == 2)
        now += RemoteDetachedActivityReader.longestUseOfAListing
        #expect(reader.listing(of: "devbox") == nil)
        now += RemoteDetachedActivityReader.retryAfterFailure
        answer.set(answers.removeFirst())
        reader.askIfDue("devbox")
        try? await Task.sleep(for: .milliseconds(300))
        #expect(calls.count == 3)
        #expect(reader.listing(of: "devbox") != nil)
    }

    // MARK: The activity sync

    @Test func aSessionWithNoTabOnAHostShowsWhatItsCLIDoesAndNotifies() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let conversation = Conversation.fixture(provider: .claude, sessionID: Self.claudeID, projectPath: "/srv/app", title: "Fix login", host: .ssh("devbox"))
        let notifier = RecordingSessionNotifier()
        let store = ConversationStore(adapters: [], sessionNotifier: notifier, startsBackgroundPolling: false)
        store.replaceConversations(on: .ssh("devbox"), with: [conversation])
        store.tmuxSessionNamesByHost[.ssh("devbox")] = [Self.claudeName]
        let host = StandInHost()
        store.remoteDetachedActivityReader = RemoteDetachedActivityReader(listPanes: { _ in host.panes() })
        let registry = ClaudeLiveSessionRegistry(configurationDirectory: directory.appendingPathComponent("claude"))
        func sync(option: String?) async {
            host.set(option.map { [Self.claudeName: .init(activityOption: $0, title: "✳ Fix login")] } ?? [:])
            await store.remoteDetachedActivityReader.ask("devbox")
            await store.synchronizeCLIActivity(claudeRegistry: registry, liveSessionReporting: nil)
        }

        await sync(option: "busy:")
        #expect(store.detachedCLIActivities == [conversation.id: .working])
        #expect(store.activitySummary(forProjectDirectoryKey: conversation.projectDirectoryKey).summary == "1 working")

        await sync(option: "waiting:permission prompt")
        #expect(store.detachedCLIActivities == [conversation.id: .needsInput(reason: "permission prompt")])
        await sync(option: "busy:")
        await sync(option: "idle:")
        #expect(store.detachedCLIActivities == [conversation.id: .idle])
        #expect(notifier.notifications.map(\.reason) == [.needsInput(reason: "permission prompt"), .finishedTurn])
        #expect(notifier.notifications.allSatisfy { $0.source == .detachedTmux(conversationID: conversation.id) })

        // The host no longer lists it: its CLI ended.
        await sync(option: nil)
        #expect(!store.isRunningInTmux(conversation))
        #expect(store.detachedCLIActivities.isEmpty)
    }

    /// A listing asked for before the session ran with no tab may leave it out, as one that came before it started.
    @Test func onlyALaterListingSaysTheCLIEnded() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let conversation = Conversation.fixture(provider: .codex, sessionID: Self.codexID, projectPath: "/srv/app", host: .ssh("devbox"))
        let store = ConversationStore(adapters: [], sessionNotifier: RecordingSessionNotifier(), startsBackgroundPolling: false)
        store.replaceConversations(on: .ssh("devbox"), with: [conversation])
        let host = StandInHost()
        store.remoteDetachedActivityReader = RemoteDetachedActivityReader(listPanes: { _ in host.panes() })
        let registry = ClaudeLiveSessionRegistry(configurationDirectory: directory.appendingPathComponent("claude"))
        await store.remoteDetachedActivityReader.ask("devbox")

        store.tmuxSessionNamesByHost[.ssh("devbox")] = [Self.codexName]
        await store.synchronizeCLIActivity(claudeRegistry: registry, liveSessionReporting: nil)
        #expect(store.isRunningInTmux(conversation))
    }

    @Test func aHostThatNeedsConnectIsNotAskedAndASessionWithATabIsTheTabs() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let loggedOut = Conversation.fixture(provider: .claude, sessionID: Self.claudeID, projectPath: "/srv/app", host: .ssh("vault"))
        let withTab = Conversation.fixture(provider: .codex, sessionID: Self.codexID, projectPath: "/srv/app", host: .ssh("devbox"))
        let store = ConversationStore(adapters: [], sessionNotifier: RecordingSessionNotifier(), startsBackgroundPolling: false)
        store.replaceConversations(on: .ssh("vault"), with: [loggedOut])
        store.replaceConversations(on: .ssh("devbox"), with: [withTab])
        store.tmuxSessionNamesByHost = [.ssh("vault"): [Self.claudeName], .ssh("devbox"): [Self.codexName]]
        store.sshHostsNeedingLogIn = ["vault"]
        let askedHosts = AskedHosts()
        store.remoteDetachedActivityReader = RemoteDetachedActivityReader(listPanes: { host in
            askedHosts.insert(host)
            return RemoteTmuxPanes(panesBySessionName: [:])
        })
        let tab = TerminalSession(
            engine: .swiftTerm, conversation: withTab, provider: .codex, projectPath: "/srv/app", action: .resume,
            displayTitle: "Tab",
            command: NativeCLICommand(executablePath: StandInCLI.executablePath, arguments: StandInCLI.arguments, workingDirectory: NSTemporaryDirectory(), environment: []),
            host: .ssh("devbox")
        )
        tab.startIfNeeded()
        store.openTerminal(tab)
        defer { store.closeAllTerminals() }

        await store.synchronizeCLIActivity(
            claudeRegistry: ClaudeLiveSessionRegistry(configurationDirectory: directory.appendingPathComponent("claude")),
            liveSessionReporting: nil
        )
        try? await Task.sleep(for: .milliseconds(300))

        #expect(askedHosts.hosts.isEmpty)
    }
}

/// A host's tmux sessions as a test sets them.
private final class StandInHost: @unchecked Sendable {
    private let lock = NSLock()
    private var current: [String: RemoteTmuxPanes.Pane] = [:]
    func set(_ panes: [String: RemoteTmuxPanes.Pane]) { lock.withLock { current = panes } }
    func panes() -> RemoteTmuxPanes { lock.withLock { RemoteTmuxPanes(panesBySessionName: current) } }
}

private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    var count: Int { lock.withLock { calls } }
    func increment() { lock.withLock { calls += 1 } }
}

private final class AnswerQueue: @unchecked Sendable {
    private let lock = NSLock()
    private var answer: RemoteTmuxPanes?
    init(_ answer: RemoteTmuxPanes?) { self.answer = answer }
    func set(_ answer: RemoteTmuxPanes?) { lock.withLock { self.answer = answer } }
    func next() -> RemoteTmuxPanes? { lock.withLock { answer } }
}

private final class AskedHosts: @unchecked Sendable {
    private let lock = NSLock()
    private var asked: Set<String> = []
    var hosts: Set<String> { lock.withLock { asked } }
    func insert(_ host: String) { lock.withLock { _ = asked.insert(host) } }
}
