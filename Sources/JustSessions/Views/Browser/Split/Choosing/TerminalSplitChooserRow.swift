import SwiftUI

/// One tab a split chooser lists, as Chrome's split view page lists a tab: its status and title, with where it runs and
/// what it runs under them. A click chooses it.
struct TerminalSplitChooserRow: View {
    @ObservedObject var tab: TerminalSession
    let details: String
    /// ↑ and ↓ moved to it while the chooser has the keyboard, so Return chooses it.
    let isHighlighted: Bool
    let onChoose: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onChoose) {
            HStack(spacing: 10) {
                TerminalStatusIndicator(session: tab)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: tab.displayTitle)
                        .font(ThemeFont.callout.weight(.medium))
                        .foregroundStyle(ThemePalette.ink)
                    Text(verbatim: details)
                        .font(ThemeFont.detail)
                        .foregroundStyle(ThemePalette.secondaryText)
                }
                .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(height: InterfaceScale.points(44))
            .background {
                if isHighlighted {
                    Rectangle().fill(ThemePalette.pressedFill)
                } else if isHovered {
                    Rectangle().fill(ThemePalette.hoverFill)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ThemePressButtonStyle())
        .onHover { isHovered = $0 }
        .accessibilityAddTraits(isHighlighted ? .isSelected : [])
    }
}
