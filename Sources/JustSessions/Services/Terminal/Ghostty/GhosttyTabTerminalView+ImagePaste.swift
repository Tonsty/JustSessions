import AppKit

/// ⌘V and the right-click menu's Paste with only an image on the clipboard; see `TerminalImagePaste`. Ghostty pastes
/// only text and drops an empty paste, so for a CLI on this Mac the tab sends the empty paste itself, as a SwiftTerm
/// tab's paste does. The Edit menu's Paste goes to `AppTerminalView`'s own action, which the app can't override, so ⌘V
/// is taken before the menu, in `performKeyEquivalent`. Choosing Edit → Paste with the pointer still pastes nothing.
extension GhosttyTabTerminalView {
    /// Returns whether the paste was of an image, which the tab has taken.
    func pastesClipboardImage() -> Bool {
        switch imagePaste.handleClipboardImage() {
        case nil:
            return false
        case .sendNothing:
            return true
        case .sendEmptyPaste:
            // As SwiftTerm sends it: only the markers, and nothing to a program that didn't turn bracketed paste on.
            if isBracketedPasteOn { sendAsTyped(Self.emptyBracketedPaste) }
            return true
        }
    }

    private static let emptyBracketedPaste = String(
        decoding: TerminalFileDropPaste.bracketedPasteStart + TerminalFileDropPaste.bracketedPasteEnd,
        as: UTF8.self
    )
}
