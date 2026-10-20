import Foundation
import Testing
@testable import JustSessions

/// An SSH tab learns the Claude session and its chosen name from its title, never from this Mac's process registry.
@MainActor
struct RemoteClaudeLiveNameTests {
    @Test func aRemoteRenameUpdatesOnlyThatHostsTabAndRow() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let sessionID = UUID().uuidString.lowercased()
        let remote = Conversation.fixture(provider: .claude, sessionID: sessionID, title: "Remote prompt", host: .ssh("devbox"))
        let local = Conversation.fixture(provider: .claude, sessionID: sessionID, title: "Local prompt")
        let other = Conversation.fixture(provider: .claude, sessionID: sessionID, title: "Other prompt", host: .ssh("other"))
        fixture.store.replaceConversations(on: .thisMac, with: [local])
        fixture.store.replaceConversations(on: .ssh("other"), with: [other])
        fixture.store.replaceConversations(on: remote.host, with: [remote])
        let tab = fixture.openTab(remote)
        tab.updateTerminalTitle(try Self.title(sessionID: remote.sessionID, name: "Remote chosen name"))

        fixture.store.synchronizeClaudeLiveNames(registry: fixture.registry)

        #expect(tab.displayTitle == "Remote chosen name")
        #expect(fixture.title(of: remote) == "Remote chosen name")
        #expect(fixture.title(of: local) == "Local prompt")
        #expect(fixture.title(of: other) == "Other prompt")
    }

    @Test func theAppsNameWinsAndADerivedNameDoesNotRenameTheSession() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let remote = Conversation.fixture(provider: .claude, title: "First prompt", host: .ssh("devbox"))
        fixture.store.replaceConversations(on: remote.host, with: [remote])
        let tab = fixture.openTab(remote)
        tab.updateTerminalTitle(try Self.title(sessionID: remote.sessionID, name: "derived-name", source: "derived"))
        fixture.store.synchronizeClaudeLiveNames(registry: fixture.registry)
        #expect(tab.displayTitle == "First prompt")

        fixture.store.rename(remote, to: "My app name")
        tab.updateTerminalTitle(try Self.title(sessionID: remote.sessionID, name: "CLI name"))
        fixture.store.synchronizeClaudeLiveNames(registry: fixture.registry)
        #expect(tab.displayTitle == "My app name")
        #expect(fixture.title(of: remote) == "My app name")
    }

    @Test func clearFollowsTheRemoteSessionAndNamesOnlyTheNewOne() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let old = Conversation.fixture(provider: .claude, title: "Before clear", host: .ssh("devbox"))
        let new = Conversation.fixture(provider: .claude, title: "After clear", host: old.host)
        fixture.store.replaceConversations(on: old.host, with: [old, new])
        let tab = fixture.openTab(old)
        tab.updateTerminalTitle(try Self.title(sessionID: new.sessionID, name: "Continued name"))

        fixture.store.synchronizeClaudeLiveNames(registry: fixture.registry)

        #expect(tab.conversation?.id == new.id)
        #expect(tab.displayTitle == "Continued name")
        #expect(fixture.title(of: old) == "Before clear")
        #expect(fixture.title(of: new) == "Continued name")
    }

    @Test func aRemoteTabNeverUsesALocalRegistryRecordWithTheSamePID() throws {
        let fixture = try Fixture()
        defer { fixture.remove() }
        let remote = Conversation.fixture(provider: .claude, title: "Remote prompt", host: .ssh("devbox"))
        fixture.store.replaceConversations(on: remote.host, with: [remote])
        let tab = fixture.openTab(remote)
        tab.tmuxSessionName = TmuxSessionName.forConversation(remote)
        tab.tmuxPaneProcessID = 4242
        let record = try JSONSerialization.data(withJSONObject: [
            "sessionId": remote.sessionID, "name": "Unrelated local name", "nameSource": "user",
        ])
        try record.write(to: fixture.registry.sessionsDirectory.appendingPathComponent("4242.json"))
        for title in ["✳ Remote prompt", "justsessions-activity:idle:", "justsessions-claude:not-base64"] {
            tab.updateTerminalTitle(title)
            fixture.store.synchronizeClaudeLiveNames(registry: fixture.registry)
            #expect(tab.displayTitle == "Remote prompt", "\(title)")
        }
    }

    /// Base64 keeps Unicode, JSON escapes, and terminal control characters out of the OSC title itself.
    static func title(sessionID: String, name: String, source: String = "user") throws -> String {
        let data = try JSONSerialization.data(withJSONObject: [
            "sessionId": sessionID, "name": name, "nameSource": source, "status": "idle",
        ])
        return "justsessions-claude:" + data.base64EncodedString() + ":"
    }

    @MainActor
    private struct Fixture {
        let directory: URL
        let registry: ClaudeLiveSessionRegistry
        let store: ConversationStore
        let settings: IsolatedUserDefaults

        init() throws {
            directory = try makeTemporaryDirectory()
            registry = ClaudeLiveSessionRegistry(configurationDirectory: directory)
            try FileManager.default.createDirectory(at: registry.sessionsDirectory, withIntermediateDirectories: true)
            settings = try IsolatedUserDefaults()
            store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, startsBackgroundPolling: false)
        }

        func remove() {
            store.closeAllTerminals()
            settings.removeSuite()
            try? FileManager.default.removeItem(at: directory)
        }

        func title(of conversation: Conversation) -> String? {
            store.conversations.first { $0.id == conversation.id }.map { store.title(for: $0) }
        }

        func openTab(_ conversation: Conversation) -> TerminalSession {
            let tab = TerminalSession(
                engine: .swiftTerm, conversation: conversation, provider: .claude, projectPath: conversation.projectPath,
                action: .resume, displayTitle: conversation.suggestedTitle,
                command: NativeCLICommand(
                    executablePath: StandInCLI.executablePath, arguments: StandInCLI.arguments,
                    workingDirectory: directory.path, environment: []
                ),
                host: conversation.host
            )
            store.openTerminal(tab)
            return tab
        }
    }
}
