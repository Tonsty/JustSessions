import Foundation

/// Back and Forward in one workspace window as things stand: where each goes, nearest first, for the title bar's
/// buttons, their right-click menus, and the Go menu.
struct WorkspaceNavigation {
    struct Destination: Identifiable {
        let entryIndex: Int
        let location: WorkspaceLocation
        let title: String
        var id: Int { entryIndex }
    }

    var backDestinations: [Destination] = []
    var forwardDestinations: [Destination] = []
    var go: (Destination) -> Void = { _ in }

    var canGoBack: Bool { !backDestinations.isEmpty }
    var canGoForward: Bool { !forwardDestinations.isEmpty }

    func goBack() {
        if let destination = backDestinations.first { go(destination) }
    }

    func goForward() {
        if let destination = forwardDestinations.first { go(destination) }
    }
}

extension WorkspaceNavigation {
    /// The history's places that `store` can show, each named by its tab's or session's title.
    @MainActor
    init(
        history: WorkspaceNavigationHistory,
        shown: WorkspaceLocation?,
        store: ConversationStore,
        listedConversationIDs: Set<String>,
        go: @escaping (Destination) -> Void
    ) {
        let canShow = { store.canShow($0, listedConversationIDs: listedConversationIDs) }
        func destinations(_ entryIndices: [Int]) -> [Destination] {
            entryIndices.compactMap { entryIndex in
                let location = history.entries[entryIndex]
                return store.title(of: location).map { Destination(entryIndex: entryIndex, location: location, title: $0) }
            }
        }
        self.init(
            backDestinations: destinations(history.backEntryIndices(shown: shown, canShow: canShow)),
            forwardDestinations: destinations(history.forwardEntryIndices(shown: shown, canShow: canShow)),
            go: go
        )
    }
}
