import AppKit

/// See `TerminalControlKey`. AppKit offers a key with Control to `performKeyEquivalent` before `keyDown`, so
/// `SelectableTerminalView+EditingKeys` sends these from there. Once the program turns on the kitty keyboard
/// protocol, SwiftTerm encodes the key itself.
extension SelectableTerminalView {
    func bytesToSend(forControlKey event: NSEvent) -> String? {
        guard terminal.keyboardEnhancementFlags.isEmpty, let controlKey = TerminalControlKey(event) else { return nil }
        return cliRunsInTmux ? controlKey.bytesForTmux : controlKey.legacyBytes
    }
}
