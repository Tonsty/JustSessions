import SwiftUI

extension RandomTip {
    var message: LocalizedStringKey {
        switch self {
        case .resumeSession:
            "Continue any past session in its own CLI and folder: just double-click it."
        case .newSessionAnyCLI:
            "Start a session in any installed CLI, or a plain terminal, with ⌘N."
        case .readWithoutRunning:
            "Click a session to read it without starting its CLI."
        case .keepRunning:
            "Quit the app and your CLIs keep running: close tabs with **Keep running**."
        case .reopenTabs:
            "Quit or restart your Mac: your tabs reopen, and CLIs still in tmux reattach."
        case .unseenTurn:
            "A blue dot means a CLI finished a turn you haven't seen yet."
        case .sshHosts:
            "Browse and resume sessions on other machines with **Add SSH host…**."
        case .splitView:
            "Put two tabs side by side: right-click a tab for split view."
        case .dragIntoSplitView:
            "Drag a session or tab onto the terminal: to a side for split view, to the middle to show it alone."
        case .selectSeveralSessions:
            "⌘-click to select several sessions, then resume or delete them together."
        case .branch:
            "Try another direction without touching the original: **Branch** a session."
        case .waitingForYouFilter:
            "See which sessions are waiting on you: filter by **Waiting for you**."
        case .notifications:
            "Get notified when a CLI finishes a turn or needs you. Choose which in Settings → General."
        case .readingWindow:
            "Read a conversation in its own window with **Open in new window**."
        case .pin:
            "Pin your most-used sessions and projects to the top from their right-click menu."
        case .openProjectInEditor:
            "Open a project in your editor straight from its right-click menu."
        case .archiveProject:
            "Archive projects you're done with; restore them anytime from the host's **+** menu."
        case .showSubagents:
            "See the sessions a session's subagents ran: turn them on in Settings → General."
        case .dragTabToNewWindow:
            "Drag a tab out of the tab bar to give it its own window."
        case .collapseTabGroup:
            "Click a project's label in the tab bar to fold away its tabs."
        case .backAndForward:
            "Jump back to the tab or session you just left with ⌘[, forward with ⌘]."
        case .tabByPosition:
            "Switch tabs with ⌘1 to ⌘9, even while typing in a CLI."
        case .hideSidebar:
            "Give the terminal the whole window: ⌘B hides the sidebar."
        case .textSize:
            "Make text bigger or smaller with ⌘+ and ⌘−, in terminals and conversations."
        case .dropFiles:
            "Drop files from Finder onto a terminal on this Mac to paste their paths."
        case .ghosttyEngine:
            "Prefer Ghostty's renderer? Pick it in Settings → Appearance → Terminal → Engine. New tabs use it."
        case .computerUse:
            "Want computer use? Add a computer-use MCP server to your CLI, then allow Accessibility in Settings → Permissions."
        }
    }
}
