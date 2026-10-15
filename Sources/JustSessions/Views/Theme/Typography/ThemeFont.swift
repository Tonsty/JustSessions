import SwiftUI

/// The app's type scale. Views set text in one of these, so the same kind of text has the same size and weight
/// everywhere; add `.weight(_:)`, `.monospacedDigit()`, or `.monospaced()` for emphasis, counts, or code. The sizes are
/// those of the macOS text styles named in each comment, at the default interface size; every size grows or shrinks with
/// Settings → Appearance → Interface size (`InterfaceSizeStore`), and a view using them redraws when it changes.
/// Conversation text, which follows the reading text size, and the terminal set their own sizes. See
/// docs/development/ui-style.md.
@MainActor
enum ThemeFont {
    /// 17pt semibold, as `.title2`: the title of a sheet, a Settings page, the selected session, or a reading window.
    static var title: Font { scaled(17, weight: .semibold) }
    /// 13pt semibold, as `.headline`: a section's heading, and the title of a card.
    static var heading: Font { scaled(13, weight: .semibold) }
    /// 13pt, as `.body`: text to read, and the labels of Settings rows.
    static var body: Font { scaled(13) }
    /// 12pt, as `.callout`: sidebar rows, tabs, buttons, and supporting copy under a title or a field.
    static var callout: Font { scaled(12) }
    /// 11pt medium, as `.subheadline`: a field's label above it, and a row's title on a Settings page.
    static var fieldLabel: Font { scaled(11, weight: .medium) }
    /// 11pt, as `.subheadline`: a row's second line, counts, and paths.
    static var detail: Font { scaled(11) }
    /// 10pt, as `.caption`: the smallest copy, such as a message count or a session's details under its title.
    static var caption: Font { scaled(10) }

    /// A symbol drawn on its own, as a control or a mark, rather than inline with text, which takes the text's font.
    static func glyph(_ size: ThemeGlyphSize, weight: Font.Weight = .regular) -> Font {
        scaled(size.rawValue, weight: weight)
    }

    /// The system font at `size` points at the interface size.
    private static func scaled(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size * InterfaceScale.factor, weight: weight)
    }
}
