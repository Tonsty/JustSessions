import CoreText

/// Whether a font's letters fill a terminal's cells. SwiftTerm makes each cell as wide as the glyph the font names W,
/// and Ghostty's cells are adjusted to the same width; see `TerminalCellPixelSize`. Some fonts that call themselves
/// monospaced, mostly Japanese, Chinese, and Korean ones such as Osaka, BIZ UDGothic, PCMyungjo, and Lantinghei TC, name
/// no glyph W, which gives cells as wide as a Chinese character, or have letters of different widths. In both engines
/// their text spreads across the terminal with gaps between letters, and lines break early or overlap.
///
/// Core Text is thread-safe, so this can run off the main thread.
enum FontFillsTerminalCells {
    /// Every printable ASCII character has a glyph as wide as the cell, give or take this share of it.
    private static let widthTolerance: CGFloat = 0.02

    static func check(_ font: CTFont) -> Bool {
        var cellWidthGlyph = CTFontGetGlyphWithName(font, "W" as CFString)
        var cellAdvance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, &cellWidthGlyph, &cellAdvance, 1)
        let cellWidth = cellAdvance.width
        guard cellWidth > 0 else { return false }

        let characters = (32..<127).map { UniChar($0) }
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count) else { return false }
        var advances = [CGSize](repeating: .zero, count: glyphs.count)
        CTFontGetAdvancesForGlyphs(font, .horizontal, glyphs, &advances, glyphs.count)
        return advances.allSatisfy { abs($0.width - cellWidth) <= cellWidth * widthTolerance }
    }
}
