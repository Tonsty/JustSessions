import AppKit

/// Files dropped on a terminal type their paths into it, as in Terminal.app, so the CLI can read them. A tab on an SSH
/// host copies them there first; see `TabTerminalView.copyDroppedFilesToHost`. The terminal takes drops only while
/// `acceptsDroppedFiles` is on.
extension SelectableTerminalView {
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        TerminalDroppedFiles.urls(on: sender.draggingPasteboard).isEmpty ? [] : .copy
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let fileURLs = TerminalDroppedFiles.urls(on: sender.draggingPasteboard)
        guard !fileURLs.isEmpty else { return false }
        // The keyboard follows the paths, so a split pane whose tab is not selected selects it.
        onFocus?()
        window?.makeFirstResponder(self)
        if let copyDroppedFilesToHost { return copyDroppedFilesToHost(fileURLs) }
        return typeDroppedPaths(fileURLs.map(\.path))
    }

    @discardableResult
    func typeDroppedPaths(_ paths: [String]) -> Bool {
        let bytes = TerminalFileDropPaste.bytes(forPaths: paths, isBracketed: terminal.bracketedPasteMode)
        send(data: bytes[...])
        return true
    }
}
