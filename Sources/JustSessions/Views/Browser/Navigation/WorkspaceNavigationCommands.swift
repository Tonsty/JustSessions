import SwiftUI

/// Go → Back and Forward, with Chrome's ⌘[ and ⌘]. Command shortcuts never reach a tab's CLI. Chrome's other pair,
/// ⌘← and ⌘→, stays with the terminal, where it moves a shell's cursor a word; see `GhosttyAppearanceConfiguration`.
struct WorkspaceNavigationCommands: Commands {
    @ObservedObject private var languageStore = AppLanguageStore.shared
    @FocusedValue(\.workspaceNavigation) private var navigation

    var body: some Commands {
        CommandMenu(AppLocalization.string("Go", language: languageStore.language)) {
            Button(AppLocalization.string("Back", language: languageStore.language)) { navigation?.goBack() }
                .keyboardShortcut("[", modifiers: .command)
                .disabled(navigation?.canGoBack != true)
            Button(AppLocalization.string("Forward", language: languageStore.language)) { navigation?.goForward() }
                .keyboardShortcut("]", modifiers: .command)
                .disabled(navigation?.canGoForward != true)
        }
    }
}
