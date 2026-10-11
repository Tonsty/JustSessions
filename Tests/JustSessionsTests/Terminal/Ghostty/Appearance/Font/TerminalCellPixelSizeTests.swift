import AppKit
import CoreText
import Testing
@testable import JustSessions

@MainActor
struct TerminalCellPixelSizeTests {
    /// STHeiti ships with macOS and, as BIZ UDGothic and PCMyungjo, names no glyph W. Its glyph named W would be
    /// `.notdef`, a full em wide, but SwiftTerm and the size Ghostty's cells are adjusted to take its W.
    @Test func swiftTermsCellsAreAsWideAsWInAFontThatNamesNoGlyphW() throws {
        let font = try #require(NSFont(name: "STHeitiSC-Light", size: 24))
        #expect(CTFontGetGlyphWithName(font, "W" as CFString) == 0)
        let stores = try IsolatedAppearanceStores()
        defer { stores.remove() }
        let swiftTerm = SwiftTermTestTerminal(stores: stores, frame: NSRect(x: 0, y: 0, width: 600, height: 200))
        swiftTerm.view.font = font
        let backingScaleFactor = swiftTerm.window.backingScaleFactor

        let cell = TerminalCellPixelSize.swiftTerm(font: font, backingScaleFactor: backingScaleFactor)
        #expect(swiftTerm.cellPixelSize == cell)
        #expect(CGFloat(cell.width) < font.pointSize * backingScaleFactor)
    }
}
