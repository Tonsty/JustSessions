/// How many cells a character takes in a terminal row: two for East Asian wide and fullwidth characters and for emoji
/// drawn as pictures, one for everything else. Close enough to Ghostty's own table to tell where a row's text ends and
/// which character a click landed on; see `TerminalScreenRow`.
enum TerminalCellWidth {
    static func cellCount(of character: Character) -> Int {
        guard let firstScalar = character.unicodeScalars.first else { return 1 }
        if firstScalar.properties.isEmojiPresentation || character.unicodeScalars.contains(emojiPresentationSelector) {
            return 2
        }
        return wideScalarRanges.contains { $0.contains(firstScalar.value) } ? 2 : 1
    }

    /// U+FE0F, which asks for a character's emoji picture, as in ⚠️.
    private static let emojiPresentationSelector: Unicode.Scalar = "\u{FE0F}"

    /// The East Asian wide and fullwidth blocks: Hangul, CJK and its punctuation, kana, Yi, fullwidth forms, and the
    /// supplementary ideographs.
    private static let wideScalarRanges: [ClosedRange<UInt32>] = [
        0x1100...0x115F,
        0x2E80...0x303E,
        0x3041...0x33FF,
        0x3400...0x4DBF,
        0x4E00...0x9FFF,
        0xA000...0xA4CF,
        0xA960...0xA97F,
        0xAC00...0xD7A3,
        0xF900...0xFAFF,
        0xFE10...0xFE19,
        0xFE30...0xFE6F,
        0xFF00...0xFF60,
        0xFFE0...0xFFE6,
        0x1B000...0x1B2FF,
        0x20000...0x2FFFD,
        0x30000...0x3FFFD,
    ]
}
