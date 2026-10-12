/// The tips the bottom of the sidebar picks from, one at a time, each about something the app can do. The raw values are
/// saved as the tips shown so far, so a case keeps its name; a saved name no case has any more is ignored.
enum RandomTip: String, CaseIterable {
    case resumeSession
    case newSessionAnyCLI
    case readWithoutRunning
    case keepRunning
    case reopenTabs
    case unseenTurn
    case sshHosts
    case splitView
    case dragIntoSplitView
    case selectSeveralSessions
    case branch
    case waitingForYouFilter
    case notifications
    case readingWindow
    case pin
    case openProjectInEditor
    case archiveProject
    case showSubagents
    case dragTabToNewWindow
    case collapseTabGroup
    case backAndForward
    case tabByPosition
    case hideSidebar
    case textSize
    case dropFiles
    case ghosttyEngine
    case computerUse
}
