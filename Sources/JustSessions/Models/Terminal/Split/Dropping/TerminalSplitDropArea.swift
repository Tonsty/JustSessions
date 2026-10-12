import CoreGraphics

/// Where a window's terminals show, as a tab dragged over them finds the side of a split view it would show on, as a
/// session dragged into Claude Code's window or a tab dragged to the side of Chrome's: with no split shown, the half
/// under the pointer is the side the tab takes beside the shown tab, in a split that starts even; with a split shown,
/// the pane under the pointer is the one the tab takes the place of, the resize area between the panes parting them.
struct TerminalSplitDropArea: Equatable {
    /// In the window, from its top-leading corner.
    var frameInWindow: CGRect
    /// The shown split's left pane share of the panes' width, or nil while no split shows.
    var shownSplitFraction: CGFloat?

    /// The side a tab let go at `pointer`, in screen coordinates, shows on, over the area's window, whose frame on
    /// screen is `windowFrame`; nil outside the area.
    func side(atScreenPoint pointer: CGPoint, windowFrame: CGRect) -> TerminalSplit.Side? {
        side(at: CGPoint(x: pointer.x - windowFrame.minX, y: windowFrame.maxY - pointer.y))
    }

    /// The side a tab let go at `point`, in the window from its top-leading corner, shows on; nil outside the area.
    func side(at point: CGPoint) -> TerminalSplit.Side? {
        guard frameInWindow.contains(point) else { return nil }
        let boundary = frameInWindow.minX + paneFrames.resizeArea.midX
        return point.x < boundary ? .left : .right
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
