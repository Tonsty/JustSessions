import CoreGraphics
import Foundation

/// Where each window's terminals show, by its store, as `WorkspaceDetailView` reports them, and the side of a split
/// view a tab dragged over them would show on once let go, which that window highlights; see
/// `TerminalSplitDropHighlight`. A window takes out its frame as it closes, so a closed window leaves nothing behind.
@MainActor
final class TerminalSplitDropTargets: ObservableObject {
    /// The side of a window's terminals a dragged tab would show on.
    struct Target: Equatable {
        let storeID: ObjectIdentifier
        let side: TerminalSplit.Side
        /// The dragged tab's title, which the highlighted pane names.
        let tabTitle: String
    }

    @Published private(set) var shownTarget: Target?
    /// By store, in its window from the window's top-leading corner.
    private var terminalFramesByStore: [ObjectIdentifier: CGRect] = [:]
    /// By store, while its window shows a split.
    private var shownSplitFractionsByStore: [ObjectIdentifier: CGFloat] = [:]

    /// The terminals' frame in the store's window, from its top-leading corner; nil once they are gone.
    func reportTerminalFrame(_ frameInWindow: CGRect?, in store: ConversationStore) {
        terminalFramesByStore[ObjectIdentifier(store)] = frameInWindow
    }

    /// The left pane's share of the split shown in the store's window, or nil while none shows.
    func reportShownSplitFraction(_ fraction: CGFloat?, in store: ConversationStore) {
        shownSplitFractionsByStore[ObjectIdentifier(store)] = fraction
    }

    /// The side `tabIDs` would show on in a split view, let go at `pointer` in screen coordinates over the store's
    /// window, whose frame is `windowFrame`; nil off its terminals, or when they can't show in a split there.
    func side(forDropping tabIDs: [UUID], at pointer: CGPoint, in store: ConversationStore, windowFrame: CGRect) -> TerminalSplit.Side? {
        let storeID = ObjectIdentifier(store)
        guard store.canShowDroppedTabsInSplit(tabIDs), let terminalFrame = terminalFramesByStore[storeID] else { return nil }
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: shownSplitFractionsByStore[storeID])
        return area.side(atScreenPoint: pointer, windowFrame: windowFrame)
    }

    /// Highlights the target in its window, or nothing for nil.
    func show(_ target: Target?) {
        if shownTarget != target { shownTarget = target }
    }
}
