import SwiftUI

extension View {
    /// Puts the sidebar toggle in the title bar, just right of the close, minimize, and zoom buttons, with Back and
    /// Forward after it, where they stay while the sidebar is hidden. The content reads the title bar's layout from
    /// `titleBarRow`.
    func titleBarControls(isSidebarHidden: Binding<Bool>, navigation: WorkspaceNavigation) -> some View {
        modifier(TitleBarControls(isSidebarHidden: isSidebarHidden, navigation: navigation))
    }
}

/// Full screen has no title bar, so there the content moves down by a title bar's height to leave the controls a
/// strip of their own at the window's leading edge.
private struct TitleBarControls: ViewModifier {
    @Binding var isSidebarHidden: Bool
    let navigation: WorkspaceNavigation
    @State private var titleBarHeight = Self.standardTitleBarHeight

    private static let standardTitleBarHeight: CGFloat = 28
    private static let leadingInsetBesideWindowButtons: CGFloat = 78
    private static let leadingInsetInFullScreen: CGFloat = 12

    private var isFullScreen: Bool { titleBarHeight == 0 }

    private var controlsLeadingInset: CGFloat {
        isFullScreen ? Self.leadingInsetInFullScreen : Self.leadingInsetBesideWindowButtons
    }

    private var row: TitleBarRow {
        TitleBarRow(
            height: isFullScreen ? Self.standardTitleBarHeight : titleBarHeight,
            controlsTrailingEdge: controlsLeadingInset + SidebarToggleButton.width + WorkspaceNavigationButtons.width
        )
    }

    func body(content: Content) -> some View {
        let row = row
        content
            .safeAreaPadding(.top, isFullScreen ? Self.standardTitleBarHeight : 0)
            .environment(\.titleBarRow, row)
            .overlay(alignment: .topLeading) {
                HStack(spacing: 0) {
                    SidebarToggleButton(isSidebarHidden: $isSidebarHidden)
                    WorkspaceNavigationButtons(navigation: navigation)
                }
                .frame(height: row.height)
                .padding(.leading, controlsLeadingInset)
                .ignoresSafeArea(edges: .top)
            }
            .background {
                // Measured outside the padding above, so it reads the window's own title bar.
                Color.clear
                    .ignoresSafeArea(edges: .top)
                    .onGeometryChange(for: CGFloat.self, of: \.safeAreaInsets.top) { titleBarHeight = $0 }
            }
    }
}
