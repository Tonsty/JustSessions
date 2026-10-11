import AppKit
import Testing

/// Clicks a terminal in a window the way the pointer does, for a test.
@MainActor
enum TerminalClick {
    /// Moves the pointer over `column` of the terminal's first row, then presses and releases the left button there.
    static func click(_ view: NSView, column: Int, modifierFlags: NSEvent.ModifierFlags) throws {
        let location = firstRowLocation(in: view, column: column)
        view.mouseMoved(with: try event(.mouseMoved, at: location, in: view, modifierFlags: modifierFlags))
        view.mouseDown(with: try event(.leftMouseDown, at: location, in: view, modifierFlags: modifierFlags))
        view.mouseUp(with: try event(.leftMouseUp, at: location, in: view, modifierFlags: modifierFlags))
    }

    /// Moves the pointer over `column` of the terminal's first row with no keys held, as before a right-click there,
    /// and returns the right-click's press.
    static func rightClick(_ view: NSView, column: Int) throws -> NSEvent {
        let location = firstRowLocation(in: view, column: column)
        view.mouseMoved(with: try event(.mouseMoved, at: location, in: view, modifierFlags: []))
        return try event(.rightMouseDown, at: location, in: view, modifierFlags: [])
    }

    /// A right-click's press at `location` in the view's own coordinates.
    static func rightClick(_ view: NSView, at location: CGPoint) throws -> NSEvent {
        try event(.rightMouseDown, at: location, in: view, modifierFlags: [])
    }

    /// The default 13-point font's cells are a little under 8 points wide in both engines, so the column's middle is
    /// found at 7.5 points a column.
    private static func firstRowLocation(in view: NSView, column: Int) -> CGPoint {
        CGPoint(x: (CGFloat(column) + 0.5) * 7.5, y: view.bounds.height - 4)
    }

    private static func event(
        _ type: NSEvent.EventType, at location: CGPoint, in view: NSView, modifierFlags: NSEvent.ModifierFlags
    ) throws -> NSEvent {
        let window = try #require(view.window)
        return try #require(NSEvent.mouseEvent(
            with: type, location: view.convert(location, to: nil), modifierFlags: modifierFlags, timestamp: 0,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0,
            clickCount: type == .mouseMoved ? 0 : 1, pressure: type == .leftMouseUp ? 0 : 1
        ))
    }
}
