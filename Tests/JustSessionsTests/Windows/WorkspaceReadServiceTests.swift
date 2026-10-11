import Foundation
import Testing
@testable import JustSessions

@Suite(.serialized)
struct WorkspaceReadServiceTests {
    @Test @MainActor func simultaneousWindowRefreshesShareOneDiscoveryAndBothReceiveIt() async throws {
        let conversation = Conversation.fixture(sessionID: "shared-discovery")
        let adapter = BlockingCountingAdapter(conversations: [conversation])
        let resolver = NativeCLICommandResolver(searchDirectories: [], inheritedEnvironment: [:], bundledTmuxDirectory: nil)
        let service = WorkspaceReadService(adapters: [adapter], commandResolver: resolver)
        var first: ConversationStore? = ConversationStore(startsBackgroundPolling: false, readService: service)
        let second = ConversationStore(startsBackgroundPolling: false, readService: service)

        first?.refreshThisMac()
        try await expectEventually { adapter.discoveryCount == 1 }
        second.refreshThisMac()
        try await Task.sleep(for: .milliseconds(50))
        #expect(adapter.discoveryCount == 1)

        // Releasing one waiter must not cancel the producer the other window is awaiting.
        first = nil
        adapter.allowDiscoveryToFinish()
        try await expectEventually { !second.isScanningThisMac }

        #expect(second.conversations.map(\.id) == [conversation.id])
        #expect(adapter.discoveryCount == 1)
    }

    @Test @MainActor func aNewWindowStartsFreshAfterEveryBlockedWaiterCloses() async throws {
        let conversation = Conversation.fixture(sessionID: "replacement-discovery")
        let adapter = FirstDiscoveryBlocksAdapter(conversations: [conversation])
        defer { adapter.allowFirstDiscoveryToFinish() }
        let resolver = NativeCLICommandResolver(searchDirectories: [], inheritedEnvironment: [:], bundledTmuxDirectory: nil)
        let service = WorkspaceReadService(adapters: [adapter], commandResolver: resolver)
        let first = ConversationStore(startsBackgroundPolling: false, readService: service)

        first.refreshThisMac()
        try await expectEventually { adapter.discoveryCount == 1 }
        first.closeWorkspace()
        try await Task.sleep(for: .milliseconds(50))

        let replacement = ConversationStore(startsBackgroundPolling: false, readService: service)
        replacement.refreshThisMac()
        try await expectEventually { adapter.discoveryCount == 2 }
        try await expectEventually { !replacement.isScanningThisMac }
        adapter.allowFirstDiscoveryToFinish()

        #expect(replacement.conversations.map(\.id) == [conversation.id])
    }

    @Test @MainActor func aLaterRefreshStartsANewDiscovery() async throws {
        let conversation = Conversation.fixture(sessionID: "fresh-discovery")
        let adapter = BlockingCountingAdapter(conversations: [conversation], startsBlocked: false)
        let resolver = NativeCLICommandResolver(searchDirectories: [], inheritedEnvironment: [:], bundledTmuxDirectory: nil)
        let service = WorkspaceReadService(adapters: [adapter], commandResolver: resolver)
        let store = ConversationStore(startsBackgroundPolling: false, readService: service)

        store.refreshThisMac()
        try await expectEventually { !store.isScanningThisMac }
        store.refreshThisMac()
        try await expectEventually { !store.isScanningThisMac }

        #expect(adapter.discoveryCount == 2)
    }
}

private final class FirstDiscoveryBlocksAdapter: ConversationAdapter, @unchecked Sendable {
    let provider = ConversationProvider.claude
    private let lock = NSLock()
    private let firstGate = DispatchSemaphore(value: 0)
    private let conversations: [Conversation]
    private var count = 0

    init(conversations: [Conversation]) {
        self.conversations = conversations
    }

    var discoveryCount: Int { lock.withLock { count } }

    func discover() throws -> [Conversation] {
        let call = lock.withLock {
            count += 1
            return count
        }
        if call == 1 { firstGate.wait() }
        return conversations
    }

    func allowFirstDiscoveryToFinish() { firstGate.signal() }
    func arguments(for conversation: Conversation, action: ConversationAction) -> [String] { [] }
    func delete(_ conversation: Conversation) throws {}
}

private final class BlockingCountingAdapter: ConversationAdapter, @unchecked Sendable {
    let provider = ConversationProvider.claude
    private let lock = NSLock()
    private let gate = DispatchSemaphore(value: 0)
    private let conversations: [Conversation]
    private let startsBlocked: Bool
    private var count = 0

    init(conversations: [Conversation], startsBlocked: Bool = true) {
        self.conversations = conversations
        self.startsBlocked = startsBlocked
    }

    var discoveryCount: Int { lock.withLock { count } }

    func discover() throws -> [Conversation] {
        lock.withLock { count += 1 }
        if startsBlocked { gate.wait() }
        return conversations
    }

    func allowDiscoveryToFinish() { gate.signal() }
    func arguments(for conversation: Conversation, action: ConversationAction) -> [String] { [] }
    func delete(_ conversation: Conversation) throws {}
}
