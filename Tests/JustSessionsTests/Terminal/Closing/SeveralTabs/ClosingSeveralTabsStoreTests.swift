import Foundation
import Testing
@testable import JustSessions

/// Close all tabs in group… closes only that group's tabs, and a tab left open shows next.
@MainActor
struct ClosingSeveralTabsStoreTests {
    @MainActor
    private struct Fixture {
        let store: ConversationStore
        private let settings: IsolatedUserDefaults

        init() throws {
            settings = try IsolatedUserDefaults()
            store = ConversationStore(adapters: [], userDefaults: settings.userDefaults, startsBackgroundPolling: false)
        }

        @discardableResult
        func openTab(_ title: String, in projectPath: String) -> TerminalSession {
            let tab = makeTab(title, in: projectPath, startsOnceShown: false)
            store.openTerminal(tab)
            return tab
        }

        /// A tab reopened at launch and not selected yet, which has started nothing.
        func reopenTabWaitingToBeShown(_ title: String, in projectPath: String) -> TerminalSession {
            let tab = makeTab(title, in: projectPath, startsOnceShown: true)
            store.insertReopenedTerminal(tab, at: store.terminalSessions.count, selecting: false)
            return tab
        }

        private func makeTab(_ title: String, in projectPath: String, startsOnceShown: Bool) -> TerminalSession {
            TerminalSession(
                engine: .swiftTerm,
                conversation: nil,
                provider: .claude,
                projectPath: projectPath,
                action: .resume,
                displayTitle: title,
                command: NativeCLICommand(executablePath: "/usr/bin/true", arguments: [], workingDirectory: projectPath, environment: []),
                startsOnceShown: startsOnceShown
            )
        }

        func tearDown() {
            store.closeAllTerminals()
            settings.removeSuite()
        }
    }

    @Test func closingAGroupsTabsShowsATabLeftOpen() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let store = fixture.store
        let first = fixture.openTab("First", in: "/tmp/justsessions-tests/app")
        let second = fixture.openTab("Second", in: "/tmp/justsessions-tests/app")
        let other = fixture.openTab("Other", in: "/tmp/justsessions-tests/tools")
        store.selectTerminal(first.id)

        store.closeTabs([first.id, second.id], endingTmuxSessions: true)

        #expect(store.terminalSessions.map(\.id) == [other.id])
        #expect(store.selectedTerminalID == other.id)
    }

    @Test func closingAnotherGroupsTabsKeepsTheSelectedTab() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let store = fixture.store
        let first = fixture.openTab("First", in: "/tmp/justsessions-tests/app")
        let second = fixture.openTab("Second", in: "/tmp/justsessions-tests/app")
        let other = fixture.openTab("Other", in: "/tmp/justsessions-tests/tools")
        store.selectTerminal(other.id)

        store.closeTabs([first.id, second.id], endingTmuxSessions: false)

        #expect(store.terminalSessions.map(\.id) == [other.id])
        #expect(store.selectedTerminalID == other.id)
    }

    /// Tabs not yet shown have started nothing, so closing them asks nothing.
    @Test func tabsNotYetShownCloseWithoutAsking() throws {
        let fixture = try Fixture()
        defer { fixture.tearDown() }
        let store = fixture.store
        let first = fixture.reopenTabWaitingToBeShown("First", in: "/tmp/justsessions-tests/app")
        let second = fixture.reopenTabWaitingToBeShown("Second", in: "/tmp/justsessions-tests/app")
        try #require(first.isWaitingToBeShown && second.isWaitingToBeShown)

        let question = store.closingQuestion(forTabs: [first.id, second.id], tabCloseChoice: .askEachTime, plainTerminalCloseChoice: .askEachTime)

        #expect(question == .closeWithoutAsking(endingTmuxSessions: true))
    }
}
