import AppKit

/// ⌘V and both menus' Paste with only an image on the clipboard; see `TerminalImagePaste`. Ghostty pastes only text and
/// drops an empty paste, so for a CLI on this Mac the tab sends the empty paste itself, as a SwiftTerm tab's paste does.
extension GhosttyTabTerminalView {
    /// The Edit menu's Paste, which ⌘V chooses, and the right-click menu's.
    override func paste(_ sender: Any?) {
        guard !pastesClipboardImage() else { return }
        super.paste(sender)
    }

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
