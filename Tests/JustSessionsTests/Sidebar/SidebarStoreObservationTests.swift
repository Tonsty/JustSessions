import Testing
@testable import JustSessions

@MainActor
struct SidebarStoreObservationTests {
    @Test func identicalRefreshAndTabSelectionDoNotPublishButChangedTitlesDo() throws {
        let settings = try IsolatedUserDefaults()
        defer { settings.removeSuite() }
        let store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, sessionNotifier: RecordingSessionNotifier(), startsBackgroundPolling: false)
        let first = Conversation.fixture()
        let other = Conversation.fixture()
        store.replaceConversations(on: .thisMac, with: [first, other])
        let publications = StoreChangeCounter(store) { _ = $0.conversations }
        let selections = StoreChangeCounter(store) { _ = $0.selectedTerminalID }
        defer { publications.cancel(); selections.cancel() }
        store.selectTerminal(nil)
        #expect(selections.count == 0)
        store.replaceConversations(on: .thisMac, with: [first, other])
        #expect(publications.count == 0)
        store.replaceConversations(on: .thisMac, with: [first.withSuggestedTitle("Changed"), other])
        #expect(publications.count == 1)
    }
}
