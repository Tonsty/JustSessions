import AppKit
import SwiftUI

@MainActor
final class SessionReadingWindowController: NSWindowController, NSWindowDelegate {
    let readingWindow: NSWindow
    let requests = SessionReadingRequests()
    /// Where the reader is, starting at `initialPosition`.
    let readingPositionStore = TranscriptReadingPositionStore()
    private let onClose: () -> Void

    init(conversation: Conversation, store: ConversationStore, initialPosition: TranscriptReadingPosition?, onClose: @escaping () -> Void) {
        self.onClose = onClose
        if let initialPosition { readingPositionStore.record(initialPosition, for: conversation.id) }
        let content = SessionReadingView(
            store: store, conversation: conversation, readingPositionStore: readingPositionStore, requests: requests
        )
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 820, height: 760),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = store.title(for: conversation)
        window.contentViewController = NSHostingController(rootView: content.appTheme(from: .shared).appLanguage(from: .shared))
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 400, height: 350)
        readingWindow = window
        super.init(window: window)
        window.delegate = self
        window.center()
    }

    required init?(coder: NSCoder) { nil }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
