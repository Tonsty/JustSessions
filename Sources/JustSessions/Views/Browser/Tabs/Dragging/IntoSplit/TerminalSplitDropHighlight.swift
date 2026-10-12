import SwiftUI

/// Shows where a tab dragged over the window's terminals would show once let go, as Claude Code shows where a session
/// dragged into its window lands: the pane it would take, a half of a new split or a pane of the shown split, tinted
/// and outlined, with the tab's title in the middle. It moves to the other side as the pointer crosses over, and lets
/// every click through.
struct TerminalSplitDropHighlight: View {
    let store: ConversationStore
    /// The terminals, from their own top-leading corner.
    let area: TerminalSplitDropArea

    @ObservedObject private var splitDropTargets = TabDragBetweenWindows.shared.splitDropTargets
    @Environment(\.tabBarTerminalPalette) private var terminalPalette

    private static let outlineWidth: CGFloat = 2

    var body: some View {
        let target = splitDropTargets.shownTarget.flatMap { $0.storeID == ObjectIdentifier(store) ? $0 : nil }
        ZStack(alignment: .topLeading) {
            if let target {
                let paneFrame = area.paneFrame(on: target.side)
                ZStack {
                    RoundedRectangle(.card)
                        .fill(ThemePalette.pressedFill)
                    RoundedRectangle(.card)
                        .strokeBorder(ThemePalette.ink, lineWidth: Self.outlineWidth)
                    Text(target.tabTitle)
                        .font(ThemeFont.callout.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(ThemePalette.raisedSurface, in: RoundedRectangle(.control))
                        .themeShadow(.floating)
                        .padding(.horizontal, 24)
                }
                .foregroundStyle(ThemePalette.ink)
                .frame(width: paneFrame.width, height: paneFrame.height)
                .offset(x: paneFrame.minX, y: paneFrame.minY)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .animation(TabBarDragMetrics.slideAnimation, value: target)
        // It sits on the terminals' background, which can be dark in a light window or the reverse.
        .environment(\.colorScheme, terminalPalette.colorScheme)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
