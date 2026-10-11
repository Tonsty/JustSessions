import SwiftUI

/// Back and Forward through what the window showed: every tab or session it shows is recorded, by any means, and
/// going Back or Forward shows one again without recording it.
extension ConversationBrowserView {
    /// What the main area shows; see `WorkspaceLocation.shown`.
    var shownLocation: WorkspaceLocation? {
        WorkspaceLocation.shown(
            selectedTabID: store.selectedTerminalID,
            onlySelectedConversationID: sessionSelection.onlySelectedConversationID
        )
    }

    /// Moving between the two panes of a shown split keeps both on screen, so it takes the place of the current entry
    /// rather than adding one; Back then leaves the split.
    func recordShownLocation(_ location: WorkspaceLocation?, after previous: WorkspaceLocation?) {
        guard let location else { return }
        if store.areTabsOfOneSplit(previous, location) {
            navigationHistory.replaceCurrent(with: location)
        } else {
            navigationHistory.record(location)
        }
    }

    /// Back and Forward as things stand; they go nowhere while a sheet or dialog is open.
    func navigation(listedConversationIDs: Set<String>) -> WorkspaceNavigation {
        guard workspaceTabCommandsEnabled else { return WorkspaceNavigation() }
        return WorkspaceNavigation(
            history: navigationHistory,
            shown: shownLocation,
            store: store,
            listedConversationIDs: listedConversationIDs,
            go: show
        )
    }

    /// Shows the place Back or Forward goes to: selects its tab, or its session alone with no tab selected, which
    /// shows that session's conversation even while a tab runs its CLI.
    func show(_ destination: WorkspaceNavigation.Destination) {
        navigationHistory.move(to: destination.entryIndex)
        switch destination.location {
        case .tab(let tabID):
            store.selectTerminal(tabID)
        case .conversation(let conversationID):
            sessionSelection.selectOnly(conversationID)
            store.selectTerminal(nil)
        }
    }
}
