import AppKit

/// The colors a transcript text view draws in, resolved from the window's theme and appearance. Blocks read only the
/// theme and the color scheme to make them, so other environment changes leave the transcript's text alone.
struct TranscriptTextColors: Equatable {
    let primary: NSColor
    let secondary: NSColor
    let tertiary: NSColor
    /// Links, in the ink the window uses as its tint.
    let link: NSColor
    /// Find's matches are washed in the ink, and the selected one is filled with it.
    let matchHighlight: NSColor
    let selectedMatchForeground: NSColor

    init(theme: ResolvedAppTheme, isDark: Bool) {
        // The system's label color follows the window's appearance, as SwiftUI's default primary text did.
        primary = .labelColor
        secondary = ThemePalette.secondaryText.nsColor(in: theme, isDark: isDark)
        tertiary = ThemePalette.tertiaryText.nsColor(in: theme, isDark: isDark)
        link = ThemePalette.ink.nsColor(in: theme, isDark: isDark)
        matchHighlight = link
        selectedMatchForeground = ThemePalette.inkForeground.nsColor(in: theme, isDark: isDark)
    }

    func foreground(for tone: TranscriptTextTone) -> NSColor {
        switch tone {
        case .primary: primary
        case .secondary: secondary
        case .tertiary: tertiary
        }
    }
}
