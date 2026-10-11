import CoreText

/// How wide SwiftTerm makes a terminal's cells for a font, in points, before rounding to whole pixels: the advance of
/// the font's glyph for the character W, or, in a font without one, of the glyph it names W. Fonts whose glyphs are
/// unnamed or named by CID, such as BIZ UDGothic and PCMyungjo, name no glyph W, so a lookup by name alone gives
/// `.notdef`, usually a full em wide. The app's SwiftTerm fork looks W up the same way; see
/// docs/development/build-and-release.md#swiftterm-fork.
///
/// Core Text is thread-safe, so this can run off the main thread.
enum SwiftTermCellWidth {
    static func advance(of font: CTFont) -> CGFloat {
        var character: UniChar = 0x57
        var glyph: CGGlyph = 0
        if !CTFontGetGlyphsForCharacters(font, &character, &glyph, 1) {
            glyph = CTFontGetGlyphWithName(font, "W" as CFString)
        }
        var advance = CGSize.zero
        CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
        return advance.width
    }
}
