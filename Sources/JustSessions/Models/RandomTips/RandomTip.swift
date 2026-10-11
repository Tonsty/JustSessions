/// The tips the bottom of the sidebar picks from, one at a time, about things a user may not have found yet. The raw
/// values are saved as the tips shown so far, so a case keeps its name; a saved name no case has any more is ignored.
enum RandomTip: String, CaseIterable {
    case selectSeveralSessions
    case backAndForward
    case tabByPosition
    case splitView
    case keepRunning
    case searchMessages
    case findInConversation
    case readingWindow
    case hideSidebar
    case branch
    case pin
    case collapseTabGroup
    case sshHosts
    case textSize
    case selectTerminalText
    case dragTabToNewWindow
    case dropFiles
    case waitingForYouFilter
    case customizeColors
    case exportConversation
    case openProjectInEditor
    case archiveProject
    case notifications
}
