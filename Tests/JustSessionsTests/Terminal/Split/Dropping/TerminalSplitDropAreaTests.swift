import CoreGraphics
import Foundation
import Testing
@testable import JustSessions

/// A tab dragged over the terminals takes the side under the pointer: a half of a new, even split, or the pane of the
/// shown split it would replace, parted by the resize area wherever it was dragged to.
struct TerminalSplitDropAreaTests {
    /// Terminals 1026 points wide and 600 high, below a 40-point tab bar and past a 200-point sidebar; with an even
    /// split, the resize area runs from 508 to 518 in them, so the sides part at 513.
    private let terminalFrame = CGRect(x: 200, y: 40, width: 1026, height: 600)

    @Test func withNoSplitShownTheHalfUnderThePointerIsTheSide() {
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: nil)

        #expect(area.side(at: CGPoint(x: 201, y: 41)) == .left)
        #expect(area.side(at: CGPoint(x: 200 + 512, y: 300)) == .left)
        #expect(area.side(at: CGPoint(x: 200 + 513, y: 300)) == .right)
        #expect(area.side(at: CGPoint(x: 1225, y: 639)) == .right)
    }

    @Test func offTheTerminalsNoSideTakesTheTab() {
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: nil)

        // Over the tab bar, the sidebar, and past the window's edges.
        #expect(area.side(at: CGPoint(x: 600, y: 20)) == nil)
        #expect(area.side(at: CGPoint(x: 100, y: 300)) == nil)
        #expect(area.side(at: CGPoint(x: 1300, y: 300)) == nil)
        #expect(area.side(at: CGPoint(x: 600, y: 700)) == nil)
    }

    @Test func withASplitShownTheResizeAreaPartsTheSidesWhereverItWasDragged() {
        // 1000 points for the panes: the left one 300, so the resize area runs from 308 to 318.
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: 0.3)

        #expect(area.side(at: CGPoint(x: 200 + 312, y: 300)) == .left)
        #expect(area.side(at: CGPoint(x: 200 + 313, y: 300)) == .right)
        // Right of the middle, but over the right pane's left part.
        #expect(area.side(at: CGPoint(x: 200 + 400, y: 300)) == .right)
    }

    @Test func theHighlightedPaneIsThePaneTheTabWouldTake() {
        let even = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: nil)
        #expect(even.paneFrame(on: .left) == CGRect(x: 8, y: 8, width: 500, height: 584))
        #expect(even.paneFrame(on: .right) == CGRect(x: 518, y: 8, width: 500, height: 584))

        let shown = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: 0.3)
        #expect(shown.paneFrame(on: .left) == CGRect(x: 8, y: 8, width: 300, height: 584))
        #expect(shown.paneFrame(on: .right) == CGRect(x: 318, y: 8, width: 700, height: 584))
    }

    /// The pointer comes in screen coordinates, measured from the bottom, and the area in the window, from its top.
    @Test func aPointerOnScreenIsMeasuredFromTheWindowsTopLeadingCorner() {
        let area = TerminalSplitDropArea(frameInWindow: terminalFrame, shownSplitFraction: nil)
        // The window's top edge is at 1000 on screen.
        let windowFrame = CGRect(x: 100, y: 300, width: 1226, height: 700)

        #expect(area.side(atScreenPoint: CGPoint(x: 100 + 300, y: 1000 - 100), windowFrame: windowFrame) == .left)
        #expect(area.side(atScreenPoint: CGPoint(x: 100 + 900, y: 1000 - 100), windowFrame: windowFrame) == .right)
        // Over the tab bar.
        #expect(area.side(atScreenPoint: CGPoint(x: 100 + 900, y: 1000 - 20), windowFrame: windowFrame) == nil)
    }
}
