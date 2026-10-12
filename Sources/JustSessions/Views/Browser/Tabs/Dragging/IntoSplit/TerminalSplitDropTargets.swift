import CoreGraphics
import Foundation

/// Where each window's terminals show, by its store, as `WorkspaceDetailView` reports them, and where a tab or a
/// sidebar row dragged over them would show once let go, which that window highlights; see
/// `TerminalSplitDropHighlight`. A window takes out its frame as it closes, so a closed window leaves nothing behind.
@MainActor
final class TerminalSplitDropTargets: ObservableObject {
    /// Where in a window's terminals a dragged tab or session would show.
    struct Target: Equatable {
        let storeID: ObjectIdentifier
        let place: TerminalDropPlace
        /// The dragged tab's or session's title, which the highlighted pane names.
        let title: String
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

    /// The side of a split view under `pointer`, in screen coordinates, over the store's window, whose frame is
    /// `windowFrame`; nil off its terminals.
    func side(at pointer: CGPoint, in store: ConversationStore, windowFrame: CGRect) -> TerminalSplit.Side? {
        let storeID = ObjectIdentifier(store)
        guard let terminalFrame = terminalFramesByStore[storeID] else { return nil }
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: shownSplitFractionsByStore[storeID])
        return area.side(atScreenPoint: pointer, windowFrame: windowFrame)
    }

    /// Highlights the target in its window, or nothing for nil.
    func show(_ target: Target?) {
        if shownTarget != target { shownTarget = target }
    }
}
