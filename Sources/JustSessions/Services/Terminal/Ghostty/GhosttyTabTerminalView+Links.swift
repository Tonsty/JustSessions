import AppKit
import GhosttyTerminal

/// Ghostty calls this for a ⌘-click on a link, with an OSC 8 hyperlink's target or the URL or path it found. Being this
/// delegate tells Ghostty the app opens links itself. Without one, Ghostty would run `open` on any URL or path it
/// found, which opens no relative path, and would open no OSC 8 hyperlink at all.
extension GhosttyTabTerminalView: TerminalSurfaceOpenURLDelegate {
    func terminalDidRequestOpenURL(_ url: String, kind: TerminalOpenURLKind) {
        onOpenLink?(url)
    }

    /// While a program takes the mouse, as tmux does in every CLI tab on this Mac, Ghostty looks for links only with
    /// Shift held, the key that takes the mouse back from the program, and then matches them without it. SwiftTerm
    /// finds them with ⌘ alone. So a move or left-button event with ⌘ held goes to Ghostty with Shift as well, which
    /// also keeps the click from the program.
    func eventFindingLinks(_ event: NSEvent) -> NSEvent {
        let modifierFlags = event.modifierFlags
        guard modifierFlags.contains(.command), !modifierFlags.contains(.shift), terminalSurface?.isMouseCaptured == true,
              let shiftedEvent = NSEvent.mouseEvent(
                  with: event.type, location: event.locationInWindow, modifierFlags: modifierFlags.union(.shift),
                  timestamp: event.timestamp, windowNumber: event.windowNumber, context: nil,
                  eventNumber: event.eventNumber, clickCount: event.type == .mouseMoved ? 0 : event.clickCount,
                  pressure: event.pressure
              )
        else { return event }
        return shiftedEvent
    }
}
