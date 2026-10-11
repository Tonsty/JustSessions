import CoreGraphics

/// The sizes of symbols drawn on their own, through `ThemeFont.glyph(_:weight:)`, from the smallest status dot to an
/// empty state's icon.
enum ThemeGlyphSize: CGFloat {
    /// A running or ended CLI's status dot.
    case statusDot = 7
    /// A status mark that asks to be seen, such as an unseen turn's dot, and the pin.
    case statusMark = 8
    /// Disclosure chevrons, a tab's close button, and a host's symbol in a tab group's label.
    case small = 9
    /// Icon buttons in sidebar headings and a split pane's toolbar, a checkbox's check, and a CLI's icon in a row.
    case control = 10
    /// The sidebar toggle in the title bar.
    case titleBar = 14
    /// A CLI's icon in the selected session's badge.
    case badge = 15
    /// The icon above an empty list's message.
    case emptyState = 24
}
