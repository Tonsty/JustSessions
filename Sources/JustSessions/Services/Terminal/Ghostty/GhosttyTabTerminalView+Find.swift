import GhosttyTerminal

/// Ghostty searches through its binding actions, the ones its own find bar uses, highlighting every match and scrolling
/// the selected one to the top of the view. Its "next" match is the older one, as the app's find goes. Ghostty reports
/// how many matches it found, but the wrapper drops those reports (`TerminalCallbackBridge.handleAction`), so this tab
/// shows no count.
extension GhosttyTabTerminalView: TerminalTextFinding {
    /// `search:` takes the rest of the action as its text, colons and backslashes included. It selects no match, so
    /// the first move selects the newest.
    func findText(_ query: String) -> TerminalFindMatchCount? {
        guard !query.isEmpty else {
            endTextFind()
            return nil
        }
        performBindingAction("search:" + query)
        performBindingAction("navigate_search:next")
        return nil
    }

    func findTextAgain(_ query: String, direction: TerminalFindDirection) -> TerminalFindMatchCount? {
        switch direction {
        case .towardOlder: performBindingAction("navigate_search:next")
        case .towardNewer: performBindingAction("navigate_search:previous")
        }
        return nil
    }

    func endTextFind() {
        performBindingAction("end_search")
    }
}
