import SwiftUI

extension RandomTip {
    var message: LocalizedStringKey {
        switch self {
        case .selectSeveralSessions:
            "⌘-click or ⇧-click in the sidebar to select several sessions, then right-click one to resume or delete them together."
        case .backAndForward:
            "⌘[ and ⌘] go back and forward through the tabs and sessions this window showed. Right-click the arrows for the whole list."
        case .tabByPosition:
            "⌘1 to ⌘8 go to a tab by its position, and ⌘9 to the last one. They work while a CLI has focus too."
        case .splitView:
            "Right-click another tab and choose **New split view with current tab** to see two tabs side by side."
        case .keepRunning:
            "Close a tab with **Keep running** and its CLI carries on in tmux, even after you quit. Click its session to return."
        case .searchMessages:
            "Sidebar search also finds words inside messages. Click a matching line to open the conversation at that message."
        case .findInConversation:
            "⌘F finds text in the conversation you are reading, and ⌘G goes to the next match."
        case .readingWindow:
            "**Open in new window** gives a conversation a window of its own, so you can read it beside a terminal."
        case .hideSidebar:
            "⌘B hides the sidebar to give the terminal the whole window. Press it again to bring the sidebar back."
        case .branch:
            "**Branch** starts a new session from a copy of a conversation and leaves the original as it was."
        case .pin:
            "Right-click a session or project to pin it. Pins keep the order you give them; drag one to move it."
        case .collapseTabGroup:
            "Click a project's label in the tab bar to collapse its tabs. A collapsed group still shows when a CLI is waiting on you."
        case .sshHosts:
            "**Add SSH host…** at the bottom of the sidebar lists the sessions on another machine, ready to read and resume."
        case .textSize:
            "⌘+ and ⌘− change the text size of the terminals or the conversation you are reading, and ⌘0 goes back to the default."
        case .selectTerminalText:
            "Hold ⇧ while dragging in a terminal to select its text, then press ⌘C to copy it."
        case .dragTabToNewWindow:
            "Drag a tab out of the tab bar to give it a window of its own. Its CLI keeps running."
        case .dropFiles:
            "Drop files from Finder on a tab on this Mac to type their paths into it."
        case .waitingForYouFilter:
            "**Waiting for you** in the sidebar's filter menu lists sessions that stopped for your answer or finished a turn you haven't seen."
        case .customizeColors:
            "Settings → Appearance can customize your theme's colors, and the terminal's colors and font."
        case .exportConversation:
            "Right-click a session to copy its conversation, or export it as Markdown or plain text."
        case .openProjectInEditor:
            "Right-click a project to open it in Finder or in an editor you have installed."
        case .archiveProject:
            "Archive a project you are done with. The host's **+** menu brings it back from **Archived projects**."
        case .notifications:
            "Sessions on this Mac can notify you when a turn ends or a CLI needs your input. Choose which in Settings → General."
        }
    }
}
