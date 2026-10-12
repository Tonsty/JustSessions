import SwiftUI

/// Back and Forward through what the window showed: every tab or session it shows is recorded, by any means, and
/// going Back or Forward shows one again without recording it.
///
/// What the window shows changes with every tab switch, and recording it changes the history, so both are read here,
/// in this modifier's body, rather than in the browser's: a switch then redraws the title bar's controls, not the
/// browser and its whole sidebar.
struct WorkspaceNavigationControls: ViewModifier {
    let store: ConversationStore
    @Binding var history: WorkspaceNavigationHistory
    @Binding var sessionSelection: SessionMultiSelection
    @Binding var isSidebarHidden: Bool
    let listedConversationIDs: Set<String>
    /// Back and Forward go nowhere while a sheet or dialog is open.
    let isEnabled: Bool

    /// What the main area shows; see `WorkspaceLocation.shown`.
    private var shownLocation: WorkspaceLocation? {
        WorkspaceLocation.shown(
            selectedTabID: store.selectedTerminalID,
            onlySelectedConversationID: sessionSelection.onlySelectedConversationID
        )
    }

    func body(content: Content) -> some View {
        let navigation = navigation
        content
            .titleBarControls(isSidebarHidden: $isSidebarHidden, navigation: navigation)
            .focusedSceneValue(\.workspaceNavigation, navigation)
            .onChange(of: shownLocation, initial: true) { previous, location in
                recordShownLocation(location, after: previous)
            }
    }

    /// Back and Forward as things stand.
    private var navigation: WorkspaceNavigation {
        guard isEnabled else { return WorkspaceNavigation() }
        return WorkspaceNavigation(
            history: history,
            shown: shownLocation,
            store: store,
            listedConversationIDs: listedConversationIDs,
            go: show
        )
    }

    /// Moving between the two panes of a shown split keeps both on screen, so it takes the place of the current entry
    /// rather than adding one; Back then leaves the split.
    private func recordShownLocation(_ location: WorkspaceLocation?, after previous: WorkspaceLocation?) {
        guard let location else { return }
        if store.areTabsOfOneSplit(previous, location) {
            history.replaceCurrent(with: location)
        } else {
            history.record(location)
        }
    }

    /// Shows the place Back or Forward goes to: selects its tab, or its session alone with no tab selected, which
    /// shows that session's conversation even while a tab runs its CLI.
    private func show(_ destination: WorkspaceNavigation.Destination) {
        history.move(to: destination.entryIndex)
        switch destination.location {
        case .tab(let tabID):
            store.selectTerminal(tabID)
        case .conversation(let conversationID):
            sessionSelection.selectOnly(conversationID)
            store.selectTerminal(nil)
        }
    }
}
