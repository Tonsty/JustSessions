import AppKit

/// What a right-click on a link offers, above the rest of the menu; see `TerminalLinkActions`.
extension TerminalContextMenu {
    var linkItems: [NSMenuItem] {
        guard let linkUnderPointer else { return [] }
        return TerminalLinkActions(store: store, tab: tab, language: language, editorStore: editorStore)
            .menuItems(for: linkUnderPointer)
    }
}
