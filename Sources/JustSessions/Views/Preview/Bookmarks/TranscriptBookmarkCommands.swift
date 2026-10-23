import AppKit
import SwiftUI

/// Bookmarks → Add or Remove Bookmark (⌘D), Next Bookmark (⌘'), and Previous Bookmark (⇧⌘') act on the conversation the
/// key window shows: its preview while no tab is selected, a reading window, or, while a tab is selected, its linked
/// session (`TerminalTabBookmarks`). The target is read when an item is chosen, as View → Zoom's is (`TextZoomCommands`):
/// a focused value is missing in a reading window. Items are always enabled, since a Commands body follows neither the key
/// window nor the scroll position. Command shortcuts never reach a tab's CLI.
struct TranscriptBookmarkCommands: Commands {
    @ObservedObject private var languageStore = AppLanguageStore.shared

    var body: some Commands {
        CommandMenu(AppLocalization.string("Bookmarks", language: languageStore.language)) {
            Button(AppLocalization.string("Add or Remove Bookmark", language: languageStore.language)) { target?.toggleBookmark() }
                .keyboardShortcut("d", modifiers: .command)
            Divider()
            Button(AppLocalization.string("Next Bookmark", language: languageStore.language)) { target?.goToAdjacentBookmark(true) }
                .keyboardShortcut("'", modifiers: .command)
            // Declared with the unshifted key, as Shift-Command-[ is in WorkspaceTabCommands.
            Button(AppLocalization.string("Previous Bookmark", language: languageStore.language)) { target?.goToAdjacentBookmark(false) }
                .keyboardShortcut("'", modifiers: [.command, .shift])
        }
    }

    private var target: TranscriptBookmarkCommandTarget? {
        TranscriptBookmarkTargetRegistry.shared.target(keyWindow: NSApp.keyWindow)
    }
}
