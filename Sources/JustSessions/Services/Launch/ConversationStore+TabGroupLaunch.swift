import Foundation

/// A tab's right-click menu starts a new session or a plain terminal in the tab's project, so the new tab joins its
/// group. A tab of a split across projects keeps its own project there, so a tab started from it opens with its
/// project's tabs.
extension ConversationStore {
    /// The tab's project folder, on the tab's host.
    func groupLocation(of tab: TerminalSession) -> ProjectLocation {
        ProjectLocation(key: tab.projectDirectoryKey)
    }

    func launchNewSession(provider: ConversationProvider, inGroupOf tab: TerminalSession) {
        launchNewSessionFromProject(provider: provider, projectPath: tab.projectDirectoryKey)
    }

    func openPlainTerminal(inGroupOf tab: TerminalSession) {
        openPlainTerminal(in: groupLocation(of: tab))
    }
}
