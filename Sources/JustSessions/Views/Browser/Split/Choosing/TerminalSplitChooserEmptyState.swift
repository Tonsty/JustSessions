import SwiftUI

/// A split chooser with no tab to list, which Chrome fills with a new tab: New Session… starts one in the chooser's
/// place.
struct TerminalSplitChooserEmptyState: View {
    let onNewSession: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.split.2x1")
                .font(ThemeFont.glyph(.emptyState))
                .foregroundStyle(ThemePalette.secondaryText)
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text("Complete your split view")
                    .font(ThemeFont.heading)
                    .foregroundStyle(ThemePalette.ink)
                Text("Start a new session to show it here.")
                    .font(ThemeFont.callout)
                    .foregroundStyle(ThemePalette.secondaryText)
            }
            .multilineTextAlignment(.center)
            Button("New Session…", action: onNewSession)
                .buttonStyle(QuietBorderedButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
