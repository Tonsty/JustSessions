import CoreText
import Testing

/// BIZ UDGothic, a font macOS downloads on demand, as from Font Book, so many Macs don't have it. It names no glyph W,
/// and every ASCII character in it is half a Chinese character wide.
enum BIZUDGothicFont {
    static let family = "BIZ UDGothic"
    static let needsTheFont: Comment = "Needs BIZ UDGothic, which macOS downloads on demand"

    static var isInstalled: Bool {
        (CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? []).contains(family)
    }
}
