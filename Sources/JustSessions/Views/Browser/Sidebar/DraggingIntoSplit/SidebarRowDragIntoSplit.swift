import AppKit

/// Follows a sidebar row dragged onto its window's terminals, which light up where it would show once let go, as for a
/// tab dragged from the tab bar, and shows it there when let go; see `ConversationStore.showDroppedRow(_:onSide:)`. Only
/// the row's own window takes it, while no other window is in front of it under the pointer.
@MainActor
final class SidebarRowDragIntoSplit {
    static let shared = SidebarRowDragIntoSplit()

    private struct Drag {
        let row: SidebarDraggedRow
        let store: ConversationStore
        /// The side of the terminals under the pointer, while the row would show there.
        let side: TerminalSplit.Side?
    }

    private var drag: Drag?
    private var splitDropTargets: TerminalSplitDropTargets { TabDragBetweenWindows.shared.splitDropTargets }

    private init() {}

    /// Follows the pointer, highlighting where the row, which the highlight names `title`, would show while it is over
    /// the terminals of the store's window.
    func follow(_ row: SidebarDraggedRow, titled title: String, in store: ConversationStore) {
        let side = sideOfTerminals(at: NSEvent.mouseLocation, in: store)
        let place = side.flatMap { store.dropPlace(for: row, onSide: $0) }
        drag = Drag(row: row, store: store, side: place == nil ? nil : side)
        splitDropTargets.show(place.map { TerminalSplitDropTargets.Target(storeID: ObjectIdentifier(store), place: $0, title: title) })
    }

    /// Ends the drag, showing the row where it was let go over the terminals, if it was. Returns whether it did.
    @discardableResult
    func drop() -> Bool {
        defer { cancel() }
        guard let drag, let side = drag.side else { return false }
        drag.store.showDroppedRow(drag.row, onSide: side)
        return true
    }

    /// Ends the drag of `row`, if it goes on, leaving everything as it was.
    func cancel(_ row: SidebarDraggedRow) {
        if drag?.row == row { cancel() }
    }

    private func cancel() {
        drag = nil
        splitDropTargets.show(nil)
    }

    /// The side of the terminals of the store's window under `pointer`, in screen coordinates; nil off them, or while
    /// another window is in front there.
    private func sideOfTerminals(at pointer: CGPoint, in store: ConversationStore) -> TerminalSplit.Side? {
        guard let window = store.windowRegistry.window(of: store),
              NSWindow.windowNumber(at: pointer, belowWindowWithWindowNumber: 0) == window.windowNumber else { return nil }
        return splitDropTargets.side(at: pointer, in: store, windowFrame: window.frame)
    }
}
