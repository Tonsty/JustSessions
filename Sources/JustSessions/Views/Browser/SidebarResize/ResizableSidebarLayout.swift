import SwiftUI

struct ResizableSidebarLayout<Sidebar: View, Detail: View>: View {
    let isSidebarHidden: Bool
    let sidebar: Sidebar
    let detail: Detail

    private let minimumDetailWidth: CGFloat = 600
    private let dividerWidth: CGFloat = 1

    /// The width at the default interface size: the sidebar shows it at a larger interface size, so its rows hold as
    /// much of their titles, and as it is at a smaller one, which shows more of them. A width saved before the interface
    /// size could change was saved at the default.
    @AppStorage("conversationSidebarWidth") private var savedSidebarWidth = 248.0
    @State private var draggingSidebarWidth: CGFloat?

    init(
        isSidebarHidden: Bool,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.isSidebarHidden = isSidebarHidden
        self.sidebar = sidebar()
        self.detail = detail()
    }

    var body: some View {
        GeometryReader { geometry in
            // Never narrower than at the default size: below it, the header's spacing, which doesn't shrink, would leave
            // no room for the app's name.
            let interfaceScale = max(InterfaceScale.factor, 1)
            let minimumSidebarWidth = 200 * interfaceScale
            let maximumSidebarWidth = max(
                minimumSidebarWidth,
                min(480 * interfaceScale, geometry.size.width - minimumDetailWidth - dividerWidth)
            )
            // Rounded so a saved fractional width or a fractional window-derived maximum cannot put the divider
            // and the sidebar's text on sub-pixel offsets.
            let sidebarWidth = min(
                max((draggingSidebarWidth ?? CGFloat(savedSidebarWidth) * interfaceScale).rounded(), minimumSidebarWidth),
                maximumSidebarWidth
            ).rounded(.down)

            HStack(spacing: 0) {
                // A hidden sidebar stays in the view tree, past the window's leading edge, so it comes back with its
                // expanded projects and scroll position.
                sidebar
                    .frame(width: sidebarWidth)
                    .frame(width: isSidebarHidden ? 0 : sidebarWidth, alignment: .trailing)
                    .opacity(isSidebarHidden ? 0 : 1)
                    .disabled(isSidebarHidden)
                    .accessibilityHidden(isSidebarHidden)

                if !isSidebarHidden {
                    // The line color is translucent, and the window's own background is not one of the theme's.
                    Rectangle()
                        .fill(ThemePalette.hairline)
                        .background(ThemePalette.contentSurface)
                        .frame(width: dividerWidth)
                        .ignoresSafeArea(edges: .top)
                }

                detail.frame(minWidth: minimumDetailWidth, maxWidth: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(alignment: .topLeading) {
                // Laid over the divider and the detail's leading margin rather than beside them, so the tab bar and
                // the terminal run right up to the divider instead of meeting a strip in another color.
                if !isSidebarHidden {
                    SidebarResizeHandle(
                        width: sidebarWidth,
                        minimumWidth: minimumSidebarWidth,
                        maximumWidth: maximumSidebarWidth,
                        onChange: { draggingSidebarWidth = $0 },
                        onCommit: { newWidth in
                            savedSidebarWidth = Double(newWidth / interfaceScale)
                            draggingSidebarWidth = nil
                        }
                    )
                    .padding(.leading, sidebarWidth)
                }
            }
        }
        .frame(minWidth: isSidebarHidden ? minimumDetailWidth : 940, minHeight: 550)
    }
}
