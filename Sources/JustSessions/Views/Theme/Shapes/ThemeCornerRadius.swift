import SwiftUI

/// The corner radii of the app's rounded shapes, from a checkbox to a code block. A shape inside another, such as a
/// selected segment in its track, takes the next smaller radius so their corners stay concentric. See
/// docs/development/ui-style.md.
enum ThemeCornerRadius: CGFloat {
    /// A checkbox.
    case checkbox = 3
    /// Keycaps, inline code chips, small icon buttons in headings, and a segment inside a track.
    case small = 4
    /// Text and search fields, sidebar rows, segmented tracks, tab group labels, and compact buttons.
    case control = 6
    /// Buttons, tables, framed lists, and the terminal preview.
    case card = 8
    /// Code blocks, images, your messages in a transcript, and Settings cards.
    case panel = 10
}

extension RoundedRectangle {
    /// A rounded rectangle at one of the theme's radii, with the continuous corners of macOS controls.
    init(_ radius: ThemeCornerRadius) {
        self.init(cornerRadius: radius.rawValue, style: .continuous)
    }
}
