import AppKit

/// Files dropped on a Ghostty terminal type their paths into it, as on a SwiftTerm one; see
/// `SelectableTerminalView+FileDrop`. The terminal takes drops only while `acceptsDroppedFiles` is on.
extension GhosttyTabTerminalView {
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

    /// Each path is its own paste, which Ghostty marks as one when the program turned on bracketed paste. Ghostty
    /// takes none before it has a surface.
    @discardableResult
    func typeDroppedPaths(_ paths: [String]) -> Bool {
        var didPasteEveryPath = true
        for path in paths {
            didPasteEveryPath = paste(text: TerminalFileDropPaste.escapedPath(path) + " ") && didPasteEveryPath
        }
        return didPasteEveryPath
    }
}
