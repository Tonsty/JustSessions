import AppKit

/// What the Bookmarks menu and a message's right-click menu do in one reader, made anew each time its view updates, so it
/// acts on the pages shown.
@MainActor
struct TranscriptBookmarkCommandTarget {
    let toggleBookmark: @MainActor () -> Void
    let goToAdjacentBookmark: @MainActor (_ forward: Bool) -> Void
    let contextMenuItems: @MainActor (_ entryID: Int) -> [NSMenuItem]
    /// Edit Bookmark… (⇧⌘D): the message's bookmark, adding one first when it has none (RDR-51).
    var editBookmark: @MainActor () -> Void = {}
    /// As `toggleBookmark` and `editBookmark`, on the loaded message with this entry ID: the mark's (RDR-48).
    var toggleBookmarkOnEntry: @MainActor (_ entryID: Int) -> Void = { _ in }
    var editBookmarkOnEntry: @MainActor (_ entryID: Int) -> Void = { _ in }
}

/// The visible reader of a window, as `TextZoomTargetRegistry` finds what a window shows.
@MainActor
final class TranscriptBookmarkTargetRegistry {
    static let shared = TranscriptBookmarkTargetRegistry()

    private let reporters = NSHashTable<TranscriptBookmarkTargetReportingView>.weakObjects()

    func register(_ reporter: TranscriptBookmarkTargetReportingView) {
        reporters.add(reporter)
    }

    /// Unlike text zoom, nothing falls back to the main window: a bookmark changes saved data, so it never lands behind a
    /// sheet or dialog that has the keyboard, such as Remove all bookmarks?. A preview behind a tab isn't active.
    func target(keyWindow: NSWindow?) -> TranscriptBookmarkCommandTarget? { keyWindow.flatMap(target(in:)) }

    /// The reader a right-clicked text view is in; a window shows at most one active reader.
    func target(for view: NSView) -> TranscriptBookmarkCommandTarget? { view.window.flatMap(target(in:)) }

    /// A window's reader whether or not it has the keyboard, as for a tab's ⌘' to a reading window behind it (TRM-74).
    func target(in window: NSWindow) -> TranscriptBookmarkCommandTarget? {
        reporters.allObjects.first { $0.window === window && $0.isActive && $0.target != nil }?.target
    }
}
