import SwiftUI

extension View {
    /// Reports where the group lays out in its window to `TabDragBetweenWindows`. Applied after the group's offset, so
    /// a drag shifting it changes nothing.
    func reportsTabBarGroupSpan(_ groupKey: String, in store: ConversationStore) -> some View {
        modifier(TabBarSpanReporting(item: .group(groupKey), store: store, coordinateSpace: .global))
    }

    /// The coordinate space of a group's tabs, from its leading edge; see `reportsTabSpanInGroup(_:in:)`.
    func tabBarGroupCoordinateSpace() -> some View {
        coordinateSpace(.named(TabBarLayout.groupCoordinateSpace))
    }

    /// Reports where the tab lays out in its group to `TabDragBetweenWindows`. Applied after the tab's offset, so a
    /// drag shifting it changes nothing.
    func reportsTabSpanInGroup(_ tabID: UUID, in store: ConversationStore) -> some View {
        modifier(TabBarSpanReporting(
            item: .tab(tabID), store: store, coordinateSpace: .named(TabBarLayout.groupCoordinateSpace)
        ))
    }
}

/// Reports the view's span as it lays out, and takes it out as the view goes, unless a view that took the group's or
/// tab's place has reported it since.
private struct TabBarSpanReporting: ViewModifier {
    let item: TabBarLayouts.Item
    let store: ConversationStore
    let coordinateSpace: CoordinateSpace

    @State private var reporter = UUID()

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: TabBarLayout.Span.self) { proxy in
                let frame = proxy.frame(in: coordinateSpace)
                return TabBarLayout.Span(minX: frame.minX, width: frame.width)
            } action: { span in
                TabDragBetweenWindows.shared.layouts.report(span, of: item, in: store, by: reporter)
            }
            .onDisappear { TabDragBetweenWindows.shared.layouts.withdraw(item, in: store, by: reporter) }
    }
}
