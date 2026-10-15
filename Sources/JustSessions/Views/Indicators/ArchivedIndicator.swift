import SwiftUI

/// Small archive box shown beside an archived session's title, which is listed only while Show archived is on.
struct ArchivedIndicator: View {
    var size: ThemeGlyphSize = .statusMark

    var body: some View {
        Image(systemName: "archivebox")
            .font(ThemeFont.glyph(size, weight: .semibold))
            .foregroundStyle(ThemePalette.tertiaryText)
            .help("Archived")
            .accessibilityLabel("Archived")
    }
}
