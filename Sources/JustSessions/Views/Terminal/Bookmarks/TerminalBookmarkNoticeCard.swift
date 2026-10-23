import SwiftUI

/// Over the top-trailing corner of a tab: what ⌘D, ⌘', or ⇧⌘' did (TRM-74), for a few seconds. It floats over the
/// terminal instead of taking a row from it, so the CLI's screen keeps its size, as `TerminalSSHFileDropNotice` does, and
/// it reads the notice in its own body, so a notice never updates the terminal's view.
struct TerminalBookmarkNoticeCard: View {
    let state: TerminalBookmarkNoticeState
    @Environment(\.locale) private var locale

    var body: some View {
        if let notice = state.notice {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: notice.text(language: AppInterfaceLanguage(identifier: locale.identifier)))
                    .font(ThemeFont.callout)
                    .foregroundStyle(ThemePalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                Button(action: state.dismiss) {
                    Image(systemName: "xmark")
                        .font(ThemeFont.glyph(.control, weight: .semibold))
                        .foregroundStyle(ThemePalette.secondaryText)
                        .frame(width: InterfaceScale.points(22), height: InterfaceScale.points(22))
                        .contentShape(Circle())
                }
                .buttonStyle(ThemePlainButtonStyle(cornerRadius: nil))
                .help("Close")
                .accessibilityLabel("Close")
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: TerminalSSHFileDropNotice.maximumWidth, alignment: .leading)
            .background {
                RoundedRectangle(.card)
                    .fill(ThemePalette.raisedSurface)
                    .themeShadow(.floating)
            }
            .overlay { RoundedRectangle(.card).strokeBorder(ThemePalette.hairline) }
            .padding(TerminalSSHFileDropNotice.marginFromTerminalEdges)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("terminal.bookmark-notice")
        }
    }
}
