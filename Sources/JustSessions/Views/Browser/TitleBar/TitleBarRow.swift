import SwiftUI

/// The strip along the window's top edge that holds the close, minimize, and zoom buttons, then the sidebar toggle and
/// Back and Forward. The tab bar shares it: while the sidebar is hidden, its tabs start past those controls.
struct TitleBarRow: Equatable {
    /// The title bar's height, or in full screen the height of the strip left for the controls.
    var height: CGFloat
    /// The trailing edge of the sidebar toggle, Back, and Forward, measured from the window's leading edge.
    var controlsTrailingEdge: CGFloat
}

extension EnvironmentValues {
    @Entry var titleBarRow = TitleBarRow(height: 28, controlsTrailingEdge: 162)
}
