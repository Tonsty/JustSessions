import CoreGraphics

/// Where a window's terminals show, as a tab dragged over them finds where it would show, as a session dragged into
/// Claude Code's window or a tab dragged to the side of Chrome's: with no split shown, the third along either edge
/// under the pointer is the side the tab takes beside the shown tab, in a split that starts even, and the middle third
/// shows the tab on its own, full width; with a split shown, the pane under the pointer is the one the tab takes the
/// place of, the resize area between the panes parting them.
struct TerminalSplitDropArea: Equatable {
    /// With no split shown, the share of the width along each edge that splits; the rest, in the middle, does not.
    static let splitEdgeShare: CGFloat = 1.0 / 3

    /// In the window, from its top-leading corner.
    var frameInWindow: CGRect
    /// The shown split's left pane share of the panes' width, or nil while no split shows.
    var shownSplitFraction: CGFloat?

    /// Where a tab let go at `pointer`, in screen coordinates, shows, over the area's window, whose frame on screen is
    /// `windowFrame`; nil outside the area.
    func place(atScreenPoint pointer: CGPoint, windowFrame: CGRect) -> TerminalDropPlace? {
        place(at: CGPoint(x: pointer.x - windowFrame.minX, y: windowFrame.maxY - pointer.y))
    }

    /// Where a tab let go at `point`, in the window from its top-leading corner, shows; nil outside the area.
    func place(at point: CGPoint) -> TerminalDropPlace? {
        guard frameInWindow.contains(point) else { return nil }
        guard shownSplitFraction != nil else {
            let edgeWidth = frameInWindow.width * Self.splitEdgeShare
            if point.x < frameInWindow.minX + edgeWidth { return .split(.left) }
            if point.x >= frameInWindow.maxX - edgeWidth { return .split(.right) }
            return .wholeArea
        }
        let boundary = frameInWindow.minX + paneFrames.resizeArea.midX
        return .split(point.x < boundary ? .left : .right)
    }

    /// Where the tab dropped at `place` shows, in the area's coordinates: that side's half of a new, even split, or
    /// the shown split's pane on that side; or the whole area inside the insets a split's panes have.
    func frame(of place: TerminalDropPlace) -> CGRect {
        switch place {
        case .split(let side):
            side == .left ? paneFrames.left : paneFrames.right
        case .wholeArea:
            CGRect(origin: .zero, size: frameInWindow.size)
                .insetBy(dx: TerminalSplitLayout.contentInset, dy: TerminalSplitLayout.contentInset)
        }
    }

    private var paneFrames: TerminalSplitLayout.Frames {
        TerminalSplitLayout.frames(fraction: shownSplitFraction ?? TerminalSplitLayout.evenFraction, size: frameInWindow.size)
    }
}
