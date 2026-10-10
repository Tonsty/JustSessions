import SwiftUI

/// The app's type scale. Views set text in one of these, so the same kind of text has the same size and weight
/// everywhere; add `.weight(_:)`, `.monospacedDigit()`, or `.monospaced()` for emphasis, counts, or code. The sizes are
/// those of the macOS text styles named in each comment. Conversation text, which follows the reading text size, and
/// the terminal set their own sizes. See docs/development/ui-style.md.
enum ThemeFont {
    /// 17pt semibold, as `.title2`: the title of a sheet, a Settings page, the selected session, or a reading window.
    static let title = Font.system(size: 17, weight: .semibold)
    /// 13pt semibold, as `.headline`: a section's heading, and the title of a card.
    static let heading = Font.system(size: 13, weight: .semibold)
    /// 13pt, as `.body`: text to read, and the labels of Settings rows.
    static let body = Font.system(size: 13)
    /// 12pt, as `.callout`: sidebar rows, tabs, buttons, and supporting copy under a title or a field.
    static let callout = Font.system(size: 12)
    /// 11pt medium, as `.subheadline`: a field's label above it, and a row's title on a Settings page.
    static let fieldLabel = Font.system(size: 11, weight: .medium)
    /// 11pt, as `.subheadline`: a row's second line, counts, and paths.
    static let detail = Font.system(size: 11)
    /// 10pt, as `.caption`: the smallest copy, such as a message count or a session's details under its title.
    static let caption = Font.system(size: 10)

    /// A symbol drawn on its own, as a control or a mark, rather than inline with text, which takes the text's font.
    static func glyph(_ size: ThemeGlyphSize, weight: Font.Weight = .regular) -> Font {
        .system(size: size.rawValue, weight: weight)
    }
}
