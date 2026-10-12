import AppKit

/// Where a drag reads its events after the mouse goes down. In the app they come from the window's queue, with periodic
/// events that keep the reader scrolling while the pointer rests past its edge. Tests replay their own, because posting
/// to the queue of an app that is not running stops the main run loop that Swift Testing waits on.
@MainActor
struct TranscriptTextSelectionEventSource {
    var startTracking: () -> Void
    var nextEvent: (NSWindow) -> NSEvent?
    var stopTracking: () -> Void

    static let windowQueue = TranscriptTextSelectionEventSource(
        startTracking: { NSEvent.startPeriodicEvents(afterDelay: 0.1, withPeriod: 0.05) },
        nextEvent: { $0.nextEvent(matching: [.leftMouseDragged, .leftMouseUp, .periodic]) },
        stopTracking: { NSEvent.stopPeriodicEvents() }
    )
}
