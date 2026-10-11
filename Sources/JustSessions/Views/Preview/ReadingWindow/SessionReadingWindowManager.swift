import AppKit

/// One reading window per session, keyed by its host-qualified ID. Closing it releases its retained workspace.
@MainActor
final class SessionReadingWindowManager {
    static let shared = SessionReadingWindowManager()
    private var controllersByConversationID: [String: SessionReadingWindowController] = [:]

    /// With `showingFind`, the reader opens Find, or puts the keyboard back in it in a window already open.
    @discardableResult
    func open(
        _ conversation: Conversation, store: ConversationStore, initialPosition: TranscriptReadingPosition? = nil,
        showingFind: Bool = false
    ) -> NSWindow {
        if let controller = controllersByConversationID[conversation.id] {
            if showingFind { controller.findRequests.request() }
            controller.readingWindow.makeKeyAndOrderFront(nil)
            return controller.readingWindow
        }
        let controller = SessionReadingWindowController(conversation: conversation, store: store, initialPosition: initialPosition) { [weak self] in
            self?.controllersByConversationID.removeValue(forKey: conversation.id)
        }
        controllersByConversationID[conversation.id] = controller
        if showingFind { controller.findRequests.request() }
        let window = controller.readingWindow
        window.makeKeyAndOrderFront(nil)
        return window
    }
}
