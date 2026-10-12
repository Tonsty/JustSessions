import Foundation
import Testing
@testable import JustSessions

/// A session or open tab dragged from the sidebar onto the terminals shows there as a tab dragged from the tab bar
/// does, beside the selected tab or in place of the shown split's pane on that side, or, let go in the middle, on its
/// own; a session with no tab open resumes in a new tab to do so. With no tab selected, it fills the terminals wherever
/// it is let go: the session resumes, or the tab is selected.
@MainActor
struct SidebarRowDropStoreTests {
    @Test func aSessionWithNoTabResumesBesideTheSelectedTab() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let conversation = sandbox.conversation()
        let store = sandbox.makeStore(listing: [conversation])
        let shown = open(store, makePlainTab(in: sandbox))
        let row = SidebarDraggedRow.session(conversation)

        #expect(store.dropPlace(for: row, at: .split(.left)) == .split(.left))
        store.showDroppedRow(row, at: .split(.left))

        let resumed = try #require(store.runningTerminal(for: conversation))
        let split = try #require(store.shownSplit)
        #expect(store.sides(of: split) == TerminalSplit.Sides(left: resumed.id, right: shown.id))
        #expect(store.terminalSessions.count == 2)
        #expect(store.selectedTerminalID == resumed.id)
        expectSplitRules(store)
    }

    @Test func aSessionWithNoTabTakesThePlaceOfTheShownSplitsPane() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let conversation = sandbox.conversation()
        let store = sandbox.makeStore(listing: [conversation])
        let left = open(store, makePlainTab(in: sandbox))
        let right = open(store, makePlainTab(in: sandbox))
        store.selectTerminal(left.id)
        store.splitSelectedTerminal(with: right.id)
        let split = try #require(store.shownSplit)

        store.showDroppedRow(.session(conversation), at: .split(.right))

        let resumed = try #require(store.runningTerminal(for: conversation))
        let swapped = try #require(store.shownSplit)
        #expect(swapped.id == split.id)
        #expect(store.sides(of: swapped) == TerminalSplit.Sides(left: left.id, right: resumed.id))
        #expect(store.split(containing: right.id) == nil)
        #expect(store.selectedTerminalID == resumed.id)
        expectSplitRules(store)
    }

    @Test func withNoTabSelectedASessionJustResumes() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let conversation = sandbox.conversation()
        let store = sandbox.makeStore(listing: [conversation])
        let row = SidebarDraggedRow.session(conversation)

        // No tabs open at all, then a tab open but the preview shown.
        #expect(store.dropPlace(for: row, at: .split(.right)) == .wholeArea)
        let other = open(store, makePlainTab(in: sandbox))
        store.selectTerminal(nil)
        #expect(store.dropPlace(for: row, at: .split(.right)) == .wholeArea)

        store.showDroppedRow(row, at: .split(.right))

        let resumed = try #require(store.runningTerminal(for: conversation))
        #expect(store.selectedTerminalID == resumed.id)
        #expect(store.terminalSessions.map(\.id).contains(other.id))
        #expect(store.terminalSplits.isEmpty)
    }

    @Test func aSessionLetGoInTheMiddleResumesOnItsOwnInPlaceOfTheSelectedTab() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let conversation = sandbox.conversation()
        let store = sandbox.makeStore(listing: [conversation])
        let shown = open(store, makePlainTab(in: sandbox))
        let row = SidebarDraggedRow.session(conversation)

        #expect(store.dropPlace(for: row, at: .wholeArea) == .wholeArea)
        store.showDroppedRow(row, at: .wholeArea)

        let resumed = try #require(store.runningTerminal(for: conversation))
        #expect(store.selectedTerminalID == resumed.id)
        #expect(store.terminalSessions.map(\.id) == [shown.id, resumed.id])
        #expect(store.terminalSplits.isEmpty)
    }

    @Test func aSessionWhoseTabIsOpenHereDropsAsThatTab() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let conversation = sandbox.conversation()
        let store = sandbox.makeStore(listing: [conversation])
        store.launch(conversation, action: .resume)
        let sessionTab = try #require(store.runningTerminal(for: conversation))
        let shown = open(store, makePlainTab(in: sandbox))

        store.showDroppedRow(.session(conversation), at: .split(.right))

        let split = try #require(store.shownSplit)
        #expect(store.sides(of: split) == TerminalSplit.Sides(left: shown.id, right: sessionTab.id))
        #expect(store.terminalSessions.count == 2)
        #expect(store.selectedTerminalID == sessionTab.id)
        expectSplitRules(store)
    }

    @Test func aSessionShownAlreadyOrRunningInAnotherWindowDoesNotDrop() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let here = sandbox.conversation()
        let elsewhere = sandbox.conversation()
        let subagent = Conversation.fixture(projectPath: sandbox.project.path, parentSessionID: here.sessionID)
        let store = sandbox.makeStore(listing: [here, elsewhere, subagent])
        let otherWindow = sandbox.makeStore(listing: [here, elsewhere, subagent])
        otherWindow.launch(elsewhere, action: .resume)
        try #require(otherWindow.runningTerminal(for: elsewhere) != nil)
        store.launch(here, action: .resume)

        // Its tab is the selected one; another window's tab runs it; a subagent's session is only read.
        #expect(store.dropPlace(for: .session(here), at: .split(.left)) == nil)
        #expect(store.dropPlace(for: .session(elsewhere), at: .split(.left)) == nil)
        #expect(store.dropPlace(for: .session(subagent), at: .split(.left)) == nil)

        let tabsBefore = store.terminalSessions.map(\.id)
        store.showDroppedRow(.session(elsewhere), at: .split(.left))
        #expect(store.terminalSessions.map(\.id) == tabsBefore)
        #expect(store.terminalSplits.isEmpty)
    }

    @Test func anOpenTabDropsBesideTheSelectedTabOrIsSelectedWhileNoneIs() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let store = sandbox.makeStore()
        let first = open(store, makePlainTab(in: sandbox))
        let second = open(store, makePlainTab(in: sandbox))

        #expect(store.dropPlace(for: .openTab(second.id), at: .split(.left)) == nil)
        #expect(store.dropPlace(for: .openTab(first.id), at: .split(.left)) == .split(.left))
        #expect(store.dropPlace(for: .openTab(UUID()), at: .split(.left)) == nil)

        store.selectTerminal(nil)
        #expect(store.dropPlace(for: .openTab(first.id), at: .split(.left)) == .wholeArea)
        store.showDroppedRow(.openTab(first.id), at: .split(.left))
        #expect(store.selectedTerminalID == first.id)
        #expect(store.terminalSplits.isEmpty)

        store.showDroppedRow(.openTab(second.id), at: .split(.right))
        let split = try #require(store.shownSplit)
        #expect(store.sides(of: split) == TerminalSplit.Sides(left: first.id, right: second.id))
        #expect(store.selectedTerminalID == second.id)
        expectSplitRules(store)
    }

    @Test func anOpenTabLetGoInTheMiddleIsSelectedOnItsOwn() throws {
        let sandbox = try TerminalEngineLaunchSandbox(engine: .swiftTerm)
        defer { sandbox.tearDown() }
        let store = sandbox.makeStore()
        let first = open(store, makePlainTab(in: sandbox))
        let second = open(store, makePlainTab(in: sandbox))

        // The selected tab itself shows already.
        #expect(store.dropPlace(for: .openTab(second.id), at: .wholeArea) == nil)
        #expect(store.dropPlace(for: .openTab(first.id), at: .wholeArea) == .wholeArea)
        store.showDroppedRow(.openTab(first.id), at: .wholeArea)

        #expect(store.selectedTerminalID == first.id)
        #expect(store.terminalSessions.map(\.id) == [first.id, second.id])
        #expect(store.terminalSplits.isEmpty)
    }

    // MARK: - Helpers

    private func open(_ store: ConversationStore, _ tab: TerminalSession) -> TerminalSession {
        store.openTerminal(tab)
        return tab
    }

    /// A terminal tab in the sandbox's project, which runs nothing.
    private func makePlainTab(in sandbox: TerminalEngineLaunchSandbox) -> TerminalSession {
        TerminalSession(
            engine: .swiftTerm,
            conversation: nil,
            provider: nil,
            projectPath: sandbox.project.path,
            action: nil,
            displayTitle: "Terminal",
            command: NativeCLICommand(
                executablePath: "/usr/bin/true", arguments: [], workingDirectory: sandbox.project.path, environment: []
            )
        )
    }
}
