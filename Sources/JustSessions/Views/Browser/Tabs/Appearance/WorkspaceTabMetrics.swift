import CoreGraphics

/// Sizes shared by the tab bar, its tabs, and its group labels. The tabs' widths follow the interface size, so they hold
/// as much of their titles at every size. The bar keeps its height, so the tabs stay level with the window's buttons
/// and the title bar's controls beside them, which macOS doesn't move; at the largest size their text still fits.
@MainActor
enum WorkspaceTabMetrics {
    /// A tab's width while every tab fits in the bar. More tabs narrow together, as in Chrome.
    static var maximumWidth: CGFloat { InterfaceScale.points(200) }
    /// The narrowest a tab gets: its status and the start of its title still show. Past this, the bar scrolls.
    static var minimumWidth: CGFloat { InterfaceScale.points(72) }
    /// The narrowest a split's tab gets, each half of one tab's width: its 10-point leading padding, 10-point status,
    /// 6-point gap, and 10-point trailing padding leave 20 points, about three characters of its title.
    static var minimumSplitTabWidth: CGFloat { InterfaceScale.points(56) }
    /// Tabs narrower than this show their × only when selected or under the pointer, leaving the title more room.
    static var minimumWidthForCloseButton: CGFloat { InterfaceScale.points(100) }
    /// From a tab's top to the bottom of the tab bar, where the selected tab meets its terminal.
    nonisolated static let height: CGFloat = 28
    /// Space between the window's top edge and the tabs.
    nonisolated static let topInset: CGFloat = 4
    /// Space between the bar's edges and its first and last tabs.
    nonisolated static let horizontalInset: CGFloat = 16
    /// Space between one tab group and the next.
    nonisolated static let groupSpacing: CGFloat = 14
    nonisolated static let cornerRadius = ThemeCornerRadius.card.rawValue
    /// How far the selected tab's feet curve out past its sides at the bottom.
    nonisolated static let footRadius: CGFloat = 6
    /// The thickness of a group's underline and of the selected tab's outline, which rises from it, as Chrome's
    /// `TabGroupUnderline::kStrokeThickness` is for both.
    nonisolated static let groupLineWidth: CGFloat = 2
}
