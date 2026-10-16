import SwiftUI

/// The last row under a project that lists only its first sessions: "Show 20 more", lined up with the session titles.
struct SidebarShowMoreSessionsRow: View {
    /// How many sessions a click lists.
    let sessionCount: Int
    let onShowMore: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onShowMore) {
            Text("Show \(sessionCount) more")
                .font(ThemeFont.callout)
                .foregroundStyle(ThemePalette.secondaryText)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: InterfaceScale.points(28))
                .padding(.leading, SidebarSessionRowMetrics.leadingPadding(indentLevel: 0) + SidebarSessionRowMetrics.iconWidth + 8)
                .padding(.trailing, SidebarSessionRowMetrics.trailingPadding)
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemePlainButtonStyle(showsHover: false))
        .background(SidebarRowBackground(isSelected: false, isHovered: isHovered))
        .onHover { isHovered = $0 }
        .accessibilityLabel("Show \(sessionCount) more sessions")
    }
}
