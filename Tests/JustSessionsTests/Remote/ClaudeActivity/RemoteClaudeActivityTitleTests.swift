import Foundation
import Testing
@testable import JustSessions

/// What a Claude Code on an SSH host does, as its relay puts its registry record in the tab's title; see
/// `RemoteClaudeActivityTitle`. `RemoteClaudeActivityRelayTests` checks that tmux gives the tab these titles.
@MainActor
struct RemoteClaudeActivityTitleTests {
    private static let prefix = RemoteClaudeActivityTitle.titlePrefix

    @Test func readsTheRecordAsTheRegistryOnThisMacIsRead() {
        let records: [(String, CLIActivity)] = [
            ("busy:", .working),
            ("waiting:input needed", .needsInput(reason: "input needed")),
            ("waiting:dialog open", .needsInput(reason: "dialog open")),
            ("waiting:", .needsInput(reason: nil)),
            ("idle:", .idle),
            ("shell:", .idle),
            // What it waited for, left in the record, is no wait.
            ("idle:input needed", .idle),
        ]
        for (record, activity) in records {
            #expect(RemoteClaudeActivityTitle.activity(inTerminalTitle: Self.prefix + record) == activity, "\(record)")
        }
    }

    /// The CLI's own title before the relay first sets its option, or with tmux 2.6 the prefix alone.
    @Test func otherTitlesTellNothing() {
        let titles = ["", "✳ Claude Code", "✳ Fix login", Self.prefix, Self.prefix + ":", Self.prefix + "compacting:", "Ready | 01a10846"]
        for title in titles {
            #expect(RemoteClaudeActivityTitle.activity(inTerminalTitle: title) == nil, "\(title)")
        }
    }

    @Test func onAnSSHHostAClaudeCodeTabIsAskedOnlyItsTitle() {
        let claudeTab = Self.makeTab(for: .fixture(provider: .claude, projectPath: "/srv/app", host: .ssh("devbox")))
        claudeTab.updateTerminalTitle(Self.prefix + "busy:")
        let probe = claudeTab.cliActivityProbe
        #expect(probe?.provider == .claude)
        #expect(probe?.processID == 0)
        #expect(probe?.terminalTitle == Self.prefix + "busy:")
        #expect(probe?.sessionFile == nil)

        for provider in ConversationProvider.allCases where provider != .codex && provider != .claude {
            let tab = Self.makeTab(for: .fixture(provider: provider, projectPath: "/srv/app", host: .ssh("devbox")))
            #expect(tab.cliActivityProbe == nil, "\(provider)")
        }
    }

    @Test func aClaudeCodeTabOnAnSSHHostShowsItsTurnsNotifiesAndStaysMarkedUnseen() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let conversation = Conversation.fixture(provider: .claude, projectPath: "/srv/app", title: "Fix login", host: .ssh("devbox"))
        let notifier = RecordingSessionNotifier()
        let store = ConversationStore(adapters: [], sessionNotifier: notifier)
        store.replaceConversations(on: .ssh("devbox"), with: [conversation])
        defer { store.closeAllTerminals() }
        // Stands in for the tab's `ssh`.
        let tab = Self.makeTab(for: conversation)
        tab.startIfNeeded()
        store.openTerminal(tab)
        let registry = ClaudeLiveSessionRegistry(configurationDirectory: directory.appendingPathComponent("claude"))
        func sync(record: String) async {
            tab.updateTerminalTitle(Self.prefix + record)
            await store.synchronizeCLIActivity(claudeRegistry: registry, liveSessionReporting: nil)
        }
        var isWaitingForYou: Bool { store.sessionsWaitingForYou.conversationIDs.contains(conversation.id) }

        await sync(record: "busy:")
        #expect(tab.cliActivity == .working)
        #expect(store.activitySummary(forProjectDirectoryKey: conversation.projectDirectoryKey).summary == "1 working")

        await sync(record: "waiting:input needed")
        #expect(tab.cliActivity == .needsInput(reason: "input needed"))
        #expect(isWaitingForYou)
        await sync(record: "busy:")
        await sync(record: "idle:")
        #expect(tab.cliActivity == .idle)

        #expect(notifier.notifications.map(\.reason) == [.needsInput(reason: "input needed"), .finishedTurn])
        #expect(notifier.notifications.allSatisfy { $0.source == .tab(id: tab.id, conversationID: conversation.id) })
        // The app is in the background, so the finished turn is unseen: the blue dot.
        #expect(tab.hasUnseenFinishedTurn)
        #expect(tab.runStatus == .finishedUnseen)
        #expect(isWaitingForYou)
    }

    private static func makeTab(for conversation: Conversation) -> TerminalSession {
        TerminalSession(
            engine: .swiftTerm,
            conversation: conversation,
            provider: conversation.provider,
            projectPath: conversation.projectPath,
            action: .resume,
            displayTitle: conversation.suggestedTitle,
            command: NativeCLICommand(
                executablePath: StandInCLI.executablePath,
                arguments: StandInCLI.arguments,
                workingDirectory: NSTemporaryDirectory(),
                environment: []
            ),
            host: conversation.host
        )
    }
}
