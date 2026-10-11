import AppKit
import Testing

/// Clicks a terminal in a window the way the pointer does, for a test.
@MainActor
enum TerminalClick {
    /// Moves the pointer over `column` of the terminal's first row, then presses and releases the left button there.
    /// The default 13-point font's cells are a little under 8 points wide in both engines, so the column's middle is
    /// found at 7.5 points a column.
    static func click(_ view: NSView, column: Int, modifierFlags: NSEvent.ModifierFlags) throws {
        let window = try #require(view.window)
        let location = CGPoint(x: (CGFloat(column) + 0.5) * 7.5, y: view.bounds.height - 4)
        func event(_ type: NSEvent.EventType) throws -> NSEvent {
            try #require(NSEvent.mouseEvent(
                with: type, location: location, modifierFlags: modifierFlags, timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0,
                clickCount: type == .mouseMoved ? 0 : 1, pressure: type == .leftMouseUp ? 0 : 1
            ))
        }
        view.mouseMoved(with: try event(.mouseMoved))
        view.mouseDown(with: try event(.leftMouseDown))
        view.mouseUp(with: try event(.leftMouseUp))
    }
}
