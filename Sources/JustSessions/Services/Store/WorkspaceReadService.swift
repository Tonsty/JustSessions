import Combine
import Foundation

/// Read-heavy workspace state shared by every window. Window presentation and terminal state stay in each
/// `ConversationStore`; session discovery and message text do not need a copy per window.
@MainActor
final class WorkspaceReadService: ObservableObject {
    struct ThisMacDiscovery: Sendable {
        let conversations: [Conversation]
        let failures: [String]
        let installedProviders: Set<ConversationProvider>
        let tmuxPaneProcessIDs: [String: Int32]
    }

    let messageIndexer: SessionMessageIndexer
    let adapters: [any ConversationAdapter]
    let commandResolver: NativeCLICommandResolver
    private let discovery = ThisMacDiscoveryCoordinator()

    init(
        adapters: [any ConversationAdapter] = [
            ClaudeAdapter(), CodexAdapter(), AntigravityAdapter(), KiroAdapter(), OpenCodeAdapter(), PiAdapter(),
        ],
        commandResolver: NativeCLICommandResolver = NativeCLICommandResolver(),
        messageIndexer: SessionMessageIndexer = SessionMessageIndexer()
    ) {
        self.adapters = adapters
        self.commandResolver = commandResolver
        self.messageIndexer = messageIndexer
    }

    /// Joins a scan already in flight. The detached producer is owned by the service, so cancellation or closure of
    /// one window does not cancel the scan awaited by another.
    func discoverThisMac() async -> ThisMacDiscovery {
        await discovery.discover(adapters: adapters, commandResolver: commandResolver)
    }
}

private actor ThisMacDiscoveryCoordinator {
    private struct InFlight {
        let id: UUID
        let task: Task<WorkspaceReadService.ThisMacDiscovery, Never>
    }

    private var inFlight: InFlight?

    func discover(
        adapters: [any ConversationAdapter], commandResolver: NativeCLICommandResolver
    ) async -> WorkspaceReadService.ThisMacDiscovery {
        if let inFlight { return await inFlight.task.value }

        let id = UUID()
        let task = Task.detached(priority: .userInitiated) {
            var found: [Conversation] = []
            var failures: [String] = []
            for adapter in adapters {
                do { found += try adapter.discover() }
                catch { failures.append("\(adapter.provider.rawValue): \(error.localizedDescription)") }
            }
            let installedProviders = InstalledCLIs.onThisMac(commandResolver: commandResolver)
            // The first refresh also checks the tmux version, so tabs can run in tmux from then on.
            let tmuxPaneProcessIDs = commandResolver.refreshThisMacTmuxServer()?.appSessionPaneProcessIDs() ?? [:]
            return WorkspaceReadService.ThisMacDiscovery(
                conversations: found,
                failures: failures,
                installedProviders: installedProviders,
                tmuxPaneProcessIDs: tmuxPaneProcessIDs
            )
        }
        inFlight = InFlight(id: id, task: task)
        let result = await task.value
        if inFlight?.id == id { inFlight = nil }
        return result
    }
}
