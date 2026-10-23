import AppKit
import SwiftUI

/// Bookmarks → Add or Remove Bookmark (⌘D), Edit Bookmark… (⇧⌘D), Next Bookmark (⌘'), and Previous Bookmark (⇧⌘') act on
/// the conversation the key window shows: its preview while no tab is selected, a reading window, or, while a tab is
/// selected, its linked session (`TerminalTabBookmarks`). Show All Bookmarks… opens the list on the frontmost workspace
/// window (RDR-52). The target is read when an item is chosen, as View → Zoom's is (`TextZoomCommands`):
/// a focused value is missing in a reading window. Items are always enabled, since a Commands body follows neither the key
/// window nor the scroll position. Command shortcuts never reach a tab's CLI.
struct TranscriptBookmarkCommands: Commands {
    @ObservedObject private var languageStore = AppLanguageStore.shared

    var body: some Commands {
        CommandMenu(AppLocalization.string("Bookmarks", language: languageStore.language)) {
            Button(AppLocalization.string("Add or Remove Bookmark", language: languageStore.language)) { target?.toggleBookmark() }
                .keyboardShortcut("d", modifiers: .command)
            // Declared with the unshifted key, as Previous Bookmark is.
            Button(AppLocalization.string("Edit Bookmark…", language: languageStore.language)) { target?.editBookmark() }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Divider()
            Button(AppLocalization.string("Next Bookmark", language: languageStore.language)) { target?.goToAdjacentBookmark(true) }
                .keyboardShortcut("'", modifiers: .command)
            // Declared with the unshifted key, as Shift-Command-[ is in WorkspaceTabCommands.
            Button(AppLocalization.string("Previous Bookmark", language: languageStore.language)) { target?.goToAdjacentBookmark(false) }
                .keyboardShortcut("'", modifiers: [.command, .shift])
            Divider()
            // As Chrome's Bookmark Manager.
            Button(AppLocalization.string("Show All Bookmarks…", language: languageStore.language)) { AllBookmarksCommand.show() }
                .keyboardShortcut("b", modifiers: [.command, .option])
        }
    }

    private var target: TranscriptBookmarkCommandTarget? {
        TranscriptBookmarkTargetRegistry.shared.target(keyWindow: NSApp.keyWindow)
    }
}
