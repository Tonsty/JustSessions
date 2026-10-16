import AppKit

/// See `TerminalControlKey`. Only for a tab whose CLI runs in this Mac's tmux: elsewhere Ghostty's own bytes stay.
/// This runs before `AppTerminalView.performKeyEquivalent`, which hands Ctrl-/ to Ghostty as Ctrl-_. Ghostty sends
/// Ctrl-2 as Ctrl-Space's 0x00 and Ctrl-Backspace as Ctrl-H's 0x08, which tmux names as those keys. While an input
/// method composes text, the key belongs to it.
extension GhosttyTabTerminalView {
    func sendControlKeyToThisMacTmux(_ event: NSEvent) -> Bool {
        guard cliRunsInThisMacTmux, window?.firstResponder === self, !hasMarkedText(),
              !outputModeScanner.hasKittyKeyboardFlags, let controlKey = TerminalControlKey(event)
        else { return false }
        sendAsTyped(controlKey.bytesForThisMacTmux)
        return true
    }
}
