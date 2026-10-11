import Foundation

/// Cooperative cancellation for a local session discovery pass. Adapters should check it between filesystem or
/// database reads; individual process probes must have their own timeout.
struct ConversationDiscoveryCancellation: Sendable {
    private let isCancelledImpl: @Sendable () -> Bool

    init(isCancelled: @escaping @Sendable () -> Bool) {
        isCancelledImpl = isCancelled
    }

    var isCancelled: Bool { isCancelledImpl() }

    func checkCancellation() throws {
        if isCancelled { throw CancellationError() }
    }

    static let never = ConversationDiscoveryCancellation { false }
}

protocol ConversationAdapter: Sendable {
    var provider: ConversationProvider { get }
    func discover(cancellation: ConversationDiscoveryCancellation) throws -> [Conversation]
    func arguments(for conversation: Conversation, action: ConversationAction) -> [String]
    func delete(_ conversation: Conversation) throws
}

extension ConversationAdapter {
    /// Direct callers outside a shared refresh have no task to cancel.
    func discover() throws -> [Conversation] {
        try discover(cancellation: .never)
    }
}
