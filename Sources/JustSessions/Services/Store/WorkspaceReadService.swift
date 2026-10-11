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

    /// Joins a scan already in flight. Each caller is a waiter; when the final waiter cancels, that producer is
    /// evicted so a later window starts fresh even if a synchronous adapter call has not returned yet.
    func discoverThisMac() async throws -> ThisMacDiscovery {
        try await discovery.discover(adapters: adapters, commandResolver: commandResolver)
    }
}

private actor ThisMacDiscoveryCoordinator {
    typealias Discovery = WorkspaceReadService.ThisMacDiscovery
    private typealias Waiter = CheckedContinuation<Discovery, any Error>

    private struct InFlight {
        let id: UUID
        let task: Task<Discovery, Never>
        var waiters: [UUID: Waiter]
    }

    private var inFlight: InFlight?

    func discover(adapters: [any ConversationAdapter], commandResolver: NativeCLICommandResolver) async throws -> Discovery {
        let waiterID = UUID()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                addWaiter(
                    waiterID,
                    continuation: continuation,
                    adapters: adapters,
                    commandResolver: commandResolver
                )
            }
        } onCancel: {
            Task { await self.cancelWaiter(waiterID) }
        }
    }

    private func addWaiter(
        _ waiterID: UUID,
        continuation: Waiter,
        adapters: [any ConversationAdapter],
        commandResolver: NativeCLICommandResolver
    ) {
        if var inFlight {
            inFlight.waiters[waiterID] = continuation
            self.inFlight = inFlight
            return
        }

        let id = UUID()
        let task = Task.detached(priority: .userInitiated) {
            await Self.scan(adapters: adapters, commandResolver: commandResolver)
        }
        inFlight = InFlight(id: id, task: task, waiters: [waiterID: continuation])
        Task { [weak self] in
            let result = await task.value
            await self?.producerFinished(id: id, result: result)
        }
    }

    private func cancelWaiter(_ waiterID: UUID) {
        guard var inFlight, let waiter = inFlight.waiters.removeValue(forKey: waiterID) else { return }
        waiter.resume(throwing: CancellationError())
        guard !inFlight.waiters.isEmpty else {
            inFlight.task.cancel()
            self.inFlight = nil
            return
        }
        self.inFlight = inFlight
    }

    private func producerFinished(id: UUID, result: Discovery) {
        guard let inFlight, inFlight.id == id else { return }
        self.inFlight = nil
        for waiter in inFlight.waiters.values { waiter.resume(returning: result) }
    }

    private nonisolated static func scan(
        adapters: [any ConversationAdapter], commandResolver: NativeCLICommandResolver
    ) async -> Discovery {
        var found: [Conversation] = []
        var failures: [String] = []
        for adapter in adapters {
            do {
                found += try await cancellableSynchronousCall { try adapter.discover() }
            } catch is CancellationError {
                return cancelledDiscovery()
            } catch {
                failures.append("\(adapter.provider.rawValue): \(error.localizedDescription)")
            }
        }
        do {
            let installedProviders = try await cancellableSynchronousCall {
                InstalledCLIs.onThisMac(commandResolver: commandResolver)
            }
            // The process runners used by the tmux probes are bounded; this wrapper also lets a producer cancelled
            // by its final waiter finish without awaiting those synchronous probes.
            let tmuxPaneProcessIDs = try await cancellableSynchronousCall {
                commandResolver.refreshThisMacTmuxServer()?.appSessionPaneProcessIDs() ?? [:]
            }
            return Discovery(
                conversations: found,
                failures: failures,
                installedProviders: installedProviders,
                tmuxPaneProcessIDs: tmuxPaneProcessIDs
            )
        } catch {
            return cancelledDiscovery()
        }
    }

    private nonisolated static func cancelledDiscovery() -> Discovery {
        Discovery(conversations: [], failures: [], installedProviders: [], tmuxPaneProcessIDs: [:])
    }
}

/// Runs a legacy synchronous read without making its caller wait after cancellation. The underlying filesystem call
/// cannot be forcibly interrupted, but it no longer retains the discovery generation or blocks a later producer.
private func cancellableSynchronousCall<Value: Sendable>(
    _ operation: @escaping @Sendable () throws -> Value
) async throws -> Value {
    let call = CancellableSynchronousCall<Value>()
    return try await withTaskCancellationHandler {
        try Task.checkCancellation()
        return try await withCheckedThrowingContinuation { continuation in
            call.start(continuation: continuation, operation: operation)
        }
    } onCancel: {
        call.cancel()
    }
}

private final class CancellableSynchronousCall<Value: Sendable>: @unchecked Sendable {
    typealias Continuation = CheckedContinuation<Value, any Error>

    private let lock = NSLock()
    private var continuation: Continuation?
    private var isFinished = false

    func start(continuation: Continuation, operation: @escaping @Sendable () throws -> Value) {
        let wasCancelled = lock.withLock {
            guard !isFinished else { return true }
            self.continuation = continuation
            return false
        }
        guard !wasCancelled else {
            continuation.resume(throwing: CancellationError())
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            self.finish(with: Result { try operation() })
        }
    }

    func cancel() {
        let continuation = lock.withLock {
            guard !isFinished else { return nil as Continuation? }
            isFinished = true
            defer { self.continuation = nil }
            return self.continuation
        }
        continuation?.resume(throwing: CancellationError())
    }

    private func finish(with result: Result<Value, any Error>) {
        let continuation = lock.withLock {
            guard !isFinished else { return nil as Continuation? }
            isFinished = true
            defer { self.continuation = nil }
            return self.continuation
        }
        continuation?.resume(with: result)
    }
}
