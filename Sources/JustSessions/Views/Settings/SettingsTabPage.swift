import SwiftUI

/// The size every Settings page shares, and the margin around its content.
enum SettingsTabPageMetrics {
    /// Fits the Permissions page, and the General page with This Mac and one SSH host, without scrolling. Each further
    /// SSH host adds a row to General, which then scrolls, as the much taller Appearance page does.
    static let size = CGSize(width: 540, height: 700)
    static let contentPadding: CGFloat = 24
}

/// One page of Settings, at the size every page shares, so the sheet keeps one size when you switch pages or a
/// setting changes what a page shows. Content taller than that, such as the Appearance page, scrolls inside the page.
struct SettingsTabPage<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.vertical) {
            content()
                .padding(SettingsTabPageMetrics.contentPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: SettingsTabPageMetrics.size.width, height: SettingsTabPageMetrics.size.height)
        .background(ThemePalette.contentSurface)
    }
}
