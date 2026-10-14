import SwiftUI

extension View {
    /// Draws the tab, split, or group shifted as `display`'s drag along the bar has it: the dragged one follows the
    /// pointer above the others, and those it passes slide over. The only part of the bar that re-runs as the pointer
    /// moves. With no drag showing, nil, it stays in its place.
    func tabBarDragShift<ItemID: Hashable>(of itemID: ItemID, in display: TabBarDragDisplay<ItemID>?) -> some View {
        modifier(TabBarDragShift(itemID: itemID, display: display))
    }
}

private struct TabBarDragShift<ItemID: Hashable>: ViewModifier {
    let itemID: ItemID
    let display: TabBarDragDisplay<ItemID>?

    func body(content: Content) -> some View {
        let drag = display?.drag
        let isDragged = drag?.draggedID == itemID
        content
            .offset(x: drag?.offset(of: itemID) ?? 0)
            // The items the dragged one passes slide over; it follows the pointer itself.
            .animation(isDragged ? nil : TabBarDragMetrics.slideAnimation, value: drag?.targetIndex)
            .zIndex(isDragged ? 1 : 0)
    }
}
