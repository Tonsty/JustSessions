import SwiftUI

extension View {
    /// Reports where the window's terminals show, and the left pane's share of the split shown there, to
    /// `TabDragBetweenWindows`, so a tab dragged over them finds the side of a split view it would show on.
    func reportsTerminalSplitDropArea(in store: ConversationStore, shownSplitFraction: CGFloat?) -> some View {
        let splitDropTargets = TabDragBetweenWindows.shared.splitDropTargets
        return onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .global)
        } action: { frameInWindow in
            splitDropTargets.reportTerminalFrame(frameInWindow, in: store)
        }
        .onChange(of: shownSplitFraction, initial: true) { _, fraction in
            splitDropTargets.reportShownSplitFraction(fraction, in: store)
        }
        .onDisappear {
            splitDropTargets.reportTerminalFrame(nil, in: store)
            splitDropTargets.reportShownSplitFraction(nil, in: store)
        }
    }
}
