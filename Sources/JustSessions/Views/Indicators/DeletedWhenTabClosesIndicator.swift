import SwiftUI

/// Small hourglass beside the title of a session started with Delete the session when its tab closes, in its tab and
/// its sidebar row, so a session about to go is never taken for one that stays.
struct DeletedWhenTabClosesIndicator: View {
    var size: ThemeGlyphSize = .statusMark

    var body: some View {
        Image(systemName: "hourglass")
            .font(ThemeFont.glyph(size, weight: .semibold))
            .foregroundStyle(ThemePalette.tertiaryText)
            .help("Deleted when its tab closes")
            .accessibilityLabel("Deleted when its tab closes")
    }
}
