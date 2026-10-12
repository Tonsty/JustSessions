import SwiftUI

/// Asks once before closing every tab of a group, as a single tab's close asks: Keep running or End sessions while tmux
/// can keep some of their CLIs running, and otherwise whether to stop their CLIs and shells. It has no Don't ask again:
/// closing a group without asking happens only when each of its tabs would close without asking on its own.
///
/// Return keeps the CLIs running, or closes the tabs when nothing can keep running, and Escape cancels.
struct TabGroupCloseConfirmation: ViewModifier {
    let store: ConversationStore
    @Binding var request: TabGroupClosingRequest?

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: presentation(ofKeepOrEnd: true), presenting: request) { request in
                Button("Keep running") { close(request, endingTmuxSessions: false) }
                    .keyboardShortcut(.defaultAction)
                Button("End sessions", role: .destructive) { close(request, endingTmuxSessions: true) }
                Button("Cancel", role: .cancel) { self.request = nil }
            } message: { request in
                if case .keepOrEndCLIs(alsoStopsOthers: true) = request.question {
                    Text("Keep running leaves their CLIs running in tmux; click a session to reattach. End sessions stops them. The other tabs' CLIs and shells stop either way.")
                } else {
                    Text("Keep running leaves their CLIs running in tmux; click a session to reattach. End sessions stops them.")
                }
            }
            .alert(title, isPresented: presentation(ofKeepOrEnd: false), presenting: request) { request in
                Button("Close tabs", role: .destructive) { close(request, endingTmuxSessions: true) }
                    .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) { self.request = nil }
            } message: { _ in
                Text("The CLIs and shells running in them will stop.")
            }
            .dismissesOnClickOutside(item: $request)
    }

    private var title: Text {
        Text("Close all tabs in \(request?.projectName ?? "")?")
    }

    /// Shows the Keep running or End sessions alert, or the one that stops everything, for the request waiting.
    private func presentation(ofKeepOrEnd showsKeepOrEnd: Bool) -> Binding<Bool> {
        Binding(
            get: {
                switch request?.question {
                case .keepOrEndCLIs: showsKeepOrEnd
                case .stopEverything: !showsKeepOrEnd
                case .closeWithoutAsking, nil: false
                }
            },
            set: { isPresented in if !isPresented { request = nil } }
        )
    }

    private func close(_ request: TabGroupClosingRequest, endingTmuxSessions: Bool) {
        store.closeTabs(request.tabIDs, endingTmuxSessions: endingTmuxSessions)
        self.request = nil
    }
}
