import SwiftUI

/// A tab's terminal. The tab names the session and its group names the project, so the terminal starts right under
/// the tab bar; a bar above it appears only once the CLI has ended. On an SSH host, files dropped on it copy there
/// under a notice in its corner; see `TerminalSSHFileDropNotice`. The tab's find bar floats over the same corner, above
/// the notice.
struct TerminalWorkspaceView: View {
    @ObservedObject var session: TerminalSession
    /// The terminal is on screen, full width or as either half of a split.
    let isShown: Bool
    /// The tab is selected, so its terminal gets the keyboard.
    let isActive: Bool
    /// Shown for a remote tab whose connection ended. Reconnecting selects the tab first, as from a split pane whose
    /// tab is not selected, so the replacement it opens is selected too.
    let onReconnect: (() -> Void)?
    /// Shown for a remote tab whose command ended; see `ConversationStore+HostCheck`.
    let onCheckHost: (() -> Void)?
    /// What the remote host's heading warns of, read only once the CLI has ended, so a running tab doesn't follow the
    /// host's checks; see `TerminalEndedBar`.
    var hostProblem: () -> String? = { nil }
    /// Called when a click lands on the terminal, before it takes the keyboard.
    let onFocus: () -> Void
    /// Builds the menu a right-click on the terminal shows, with the link under the pointer, if any.
    let makeContextMenu: (_ linkUnderPointer: String?) -> NSMenu
    /// Does what ⌘-clicking a link in the terminal does.
    let onOpenLink: (_ link: String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if session.hasExited {
                TerminalEndedBar(
                    exitCode: session.exitCode,
                    endedWithErrorSoonAfterStarting: session.endedWithErrorSoonAfterStarting,
                    hostProblem: hostProblem(),
                    onCheckHost: onCheckHost,
                    onReconnect: onReconnect.map { reconnect in { onFocus(); reconnect() } }
                )
                ThemeDivider()
            }
            EmbeddedTerminalView(
                session: session,
                isShown: isShown,
                isActive: isActive,
                onFocus: onFocus,
                makeContextMenu: makeContextMenu,
                onOpenLink: onOpenLink
            )
                .id(session.id)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topTrailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        if session.findState.isPresented {
                            // The notice's margin, so the two line up when both show.
                            TerminalFindBar(findState: session.findState)
                                .padding([.top, .horizontal], TerminalSSHFileDropNotice.marginFromTerminalEdges)
                        }
                        if let sshFileDrop = session.sshFileDrop { TerminalSSHFileDropNotice(fileDrop: sshFileDrop) }
                    }
                }
        }
        // Closing the bar gives the keyboard back to the terminal of the selected tab.
        .onChange(of: session.findState.closeRevision) {
            guard isActive else { return }
            session.terminalView.window?.makeFirstResponder(session.terminalView)
        }
        // A click in the find field of a split's other pane selects its tab, so the find keys go to that bar.
        .onChange(of: session.findState.isFieldFocused) {
            if session.findState.isFieldFocused && !isActive { onFocus() }
        }
    }
}
