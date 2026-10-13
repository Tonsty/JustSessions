import AppKit

/// What a right-click in a tab's terminal offers: what to do with the link under the pointer, if any; copying,
/// pasting, and selecting its text, as a terminal app's menu does; then what the tab's menu in the tab bar offers, in
/// the same order; see `TerminalTabMenuItems`. AppKit asks for the menu on each right-click, so it is built each time,
/// from the link, the terminal's selection, the tab's session and split, the installed editors, and the language chosen
/// in Settings as they are then.
@MainActor
struct TerminalContextMenu {
    let store: ConversationStore
    let tab: TerminalSession
    let onRename: (Conversation) -> Void
    /// Asks what to do with the tab's CLI, as the tab's × does.
    let onCloseTab: (UUID) -> Void
    /// Asks to delete the tab's session, as its row's Close and delete session… does.
    let onDelete: (Conversation) -> Void
    /// The link the right-click landed on, as the terminal would hand it over for a ⌘-click; see `linkItems`.
    var linkUnderPointer: String? = nil
    /// The language chosen in Settings when nil.
    var language: AppInterfaceLanguage? = nil
    /// The editors a file or folder the link names can open in.
    var editorStore: ExternalEditorStore = .shared

    func makeMenu() -> NSMenu {
        let linkItems = linkItems
        let linkSection = linkItems.isEmpty ? [] : linkItems + [.separator()]
        let menu = makeMenu(items: linkSection + textEditingItems + [.separator()] + tabItems)
        // macOS's context menu plug-ins would add AutoFill (Contact…, Passwords…, Credit Card…), as for any view that
        // takes typing. A terminal has no form to fill.
        menu.allowsContextMenuPlugIns = false
        return menu
    }

    /// Copy needs a selection, the terminal's or ⌘A's of the CLI's prompt (`TerminalPromptSelection`). Paste needs text
    /// or an image on the clipboard; see `TerminalImagePaste`. Select All selects all of the terminal.
    private var textEditingItems: [NSMenuItem] {
        let terminalView = tab.terminalView
        let hasSelection = terminalView.selectionActive || terminalView.promptSelection.isActive
        return [
            ActionMenuItem(title: localized("Copy"), systemImage: "doc.on.doc", isEnabled: hasSelection) {
                terminalView.copy(terminalView)
            },
            ActionMenuItem(
                title: localized("Paste"),
                systemImage: "doc.on.clipboard",
                isEnabled: NSPasteboard.general.availableType(from: [.string]) != nil
                    || terminalView.imagePaste.clipboardHoldsOnlyAnImage
            ) {
                terminalView.paste(terminalView)
            },
            ActionMenuItem(title: localized("Select All"), systemImage: "selection.pin.in.out") {
                terminalView.promptSelection.cancel()
                terminalView.selectAll(terminalView)
            },
        ]
    }

    /// As the tab's menu in the tab bar has them.
    private var tabItems: [NSMenuItem] {
        if tab.isPlainTerminal { return splitItems + closingItems }
        return conversationItems + splitItems + closingItems
    }

    func localized(_ value: String.LocalizationValue) -> String {
        AppLocalization.string(value, language: language)
    }

    func makeMenu(title: String = "", items: [NSMenuItem]) -> NSMenu {
        ActionMenu.make(title: title, items: items)
    }

    func submenuItem(title: String, systemImage: String, items: [NSMenuItem]) -> NSMenuItem {
        ActionMenu.submenuItem(title: title, systemImage: systemImage, items: items)
    }
}
