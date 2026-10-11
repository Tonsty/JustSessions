import AppKit
import Testing
@testable import JustSessions

@MainActor
struct SessionReadingWindowTests {
    @Test func openingAndReusingAReadingWindowDoesNotLaunchATerminal() throws {
        _ = NSApplication.shared
        let settings = try IsolatedUserDefaults()
        defer { settings.removeSuite() }
        let store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, sessionNotifier: RecordingSessionNotifier())
        let conversation = TranscriptScrollViewFixture.conversation("read-without-resume")
        let manager = SessionReadingWindowManager()

        let firstWindow = manager.open(conversation, store: store)
        let reopenedWindow = manager.open(conversation, store: store)
        #expect(firstWindow === reopenedWindow)
        #expect(firstWindow.styleMask.contains(.resizable))
        #expect(store.terminalSessions.isEmpty)
        #expect(store.selectedTerminalID == nil)
        firstWindow.close()

        let freshWindow = manager.open(conversation, store: store)
        defer { freshWindow.close() }
        #expect(freshWindow !== firstWindow)
        #expect(store.terminalSessions.isEmpty)
    }

    /// ⌘F in a tab linked to the session opens its reading window with Find, and in a window already open asks Find
    /// again, which puts the keyboard back in its field. Opening the window otherwise asks nothing.
    @Test func openingForFindAsksTheReaderToShowFind() throws {
        _ = NSApplication.shared
        let settings = try IsolatedUserDefaults()
        defer { settings.removeSuite() }
        let store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, sessionNotifier: RecordingSessionNotifier())
        let conversation = TranscriptScrollViewFixture.conversation("find-from-tab")
        let manager = SessionReadingWindowManager()

        let window = manager.open(conversation, store: store, showingFind: true)
        defer { window.close() }
        let controller = try #require(window.windowController as? SessionReadingWindowController)
        #expect(controller.findRequests.revision == 1)

        #expect(manager.open(conversation, store: store) === window)
        #expect(controller.findRequests.revision == 1)
        #expect(manager.open(conversation, store: store, showingFind: true) === window)
        #expect(controller.findRequests.revision == 2)
        #expect(store.selectedTerminalID == nil)
    }

    @Test func sessionsOnDifferentHostsGetSeparateReadingWindows() throws {
        _ = NSApplication.shared
        let settings = try IsolatedUserDefaults()
        defer { settings.removeSuite() }
        let store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, sessionNotifier: RecordingSessionNotifier())
        let first = TranscriptScrollViewFixture.conversation("host-qualified")
        let second = first.onHost(.ssh("reading-fixture.example"))
        let manager = SessionReadingWindowManager()
        let firstWindow = manager.open(first, store: store)
        let secondWindow = manager.open(second, store: store)
        defer { firstWindow.close(); secondWindow.close() }
        #expect(firstWindow !== secondWindow)
        #expect(manager.open(first, store: store) === firstWindow)
        #expect(store.terminalSessions.isEmpty)
    }
}
